# -*- coding: utf-8 -*-

import sys; __stdout__ = sys.stdout; __stdin__ = sys.stdin; __stderr__ = open("interact.log", "a");
from leela.server.network import cassandra_proto
from leela.server.trial import helpers
from leela.server.data import parser
from twisted.internet import reactor
from leela.server.data import pp
from leela.server import config
from datetime import datetime
import contextlib
import subprocess
import threading
import traceback
import argparse
import httplib
import os.path
import struct
import select
import socket
import json
import math
import time
import sys
import re
import os

__t0__     = int(time.time())
__t0__     = __t0__ - __t0__ % 60

def dump(pipe, *msg):
    with threading.Lock():
        for x in msg:
            pipe.write(x)

def initd(opts, name):
    return(os.path.join(opts.chdir, "etc/init.d", name))

def split(s):
    args = s.split(" ", 1)
    if (len(args) == 1):
        return(args[0], {})
    else:
        params = args[1].partition("#")[0].strip()
        return(args[0], split_args(params))

def split_args(s):
    args  = []
    quote = False
    for w in expand(s).split(" "):
        if (not quote and w.startswith("\"")):
            quote = True
            args.append([w])
        elif (quote):
            args[-1].append(w)
            if (w.endswith("\"")):
                quote = False
                args.append(" ".join(args.pop())[1:-1])
        else:
            args.append(w)
    return(dict(map(lambda s: s.split("=", 1), args)))

def expand(s):
    r = r"{now(?:(\+|-)(\d+(?:s|m|h|d)))?(\|.*?)?}"
    g = re.search(r, s)
    while (g is not None):
        f = lambda t: datetime.fromtimestamp(t).strftime((g.group(3) or " %s.0")[1:])
        o = g.group(1)
        if (o is not None):
            a  = int(g.group(2)[:-1], 10)
            a *= {"s": 1, "m": 60, "h": 3600, "d": 86400}[g.group(2)[-1]]
            if (o == "+"):
                s = s[:g.start()] + f(__t0__ + a) + s[g.end():]
            elif (o == "-"):
                s = s[:g.start()] + f(__t0__ - a) + s[g.end():]
            else:
                raise(RuntimeError("the impossible happened!"))
        else:
            s = s[:g.start()] + f(__t0__) + s[g.end():]
        g = re.search(r, s)
    s = s.replace("{now}", repr(__t0__))
    s = s.replace("\\n", "\n")
    return(s)

def make_timeseries_relative(series):
    for k in range(len(series)):
        series[k] = [series[k][0] - __t0__, series[k][1]]
    return(series)

def make_events_relative(string):
    events = []
    output = []
    while (string != ""):
        e, string = parser.parse_event(string)
        events.append(e)
    for e in events:
        e.set_unixtimestamp(e.unixtimestamp() - __t0__)
        output.append(pp.render_event(e))
    return("".join(output))

def execute(opts, command, **env):
    env = dict(os.environ)
    env["CHDIR"] = opts.chdir
    p = subprocess.Popen(command, env=env, stdout=__stderr__, stderr=__stderr__)
    return(p)

def initd_start(opts, state, script):
    p = execute(opts, [initd(opts, script), "start"])
    return(p.wait())

def initd_stop(opts, state, script):
    p = execute(opts, [initd(opts, script), "stop"])
    return(p.wait())

def initd_restart(opts, state, script):
    initd_stop(opts, state, script)
    return(initd_start(opts, state, script))

def cassandra_truncate(opts, state, cf):
    storage = cassandra_proto.CassandraProto(opts.config)
    storage.startService()
    cc = storage.truncate(cf)
    cc.addCallback(lambda _: storage.stopService())
    cc.addCallback(lambda _: reactor.stop())
    reactor.run()
    return(0)

def udp_send(opts, state, message):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
    p = opts.config.getint("udp", "port")
    h = opts.config.get("udp", "address").replace("0.0.0.0", "localhost")
    s.sendto(message, 0, (h, p))
    r = select.select([s.fileno()], [], [], 1)[0]
    if (len(r) == 1):
        dump(__stdout__, s.recv(65535), "\n")
    s.close()
    return(0)

def echo(opts, state, string):
    dump(__stdout__, string, "\n")
    return(0)

def sleep(opts, state, seconds):
    time.sleep(float(seconds))
    return(0)

def http_request(opts, state, method, url, data=None):
    h = opts.config.get("http", "address")
    p = opts.config.getint("http", "port")
    e = "http://%s:%d" % (h, p)
    r = httplib.HTTPConnection(h, p)
    r.request(method, url, data)
    rply = json.loads(r.getresponse().read())
    if ("results" in rply):
        for k in rply["results"].keys():
            rply["results"][k]["series"] = make_timeseries_relative(rply["results"][k]["series"])
    dump(__stdout__, json.dumps(rply, sort_keys=True), "\n")
    return(0)

def dmproc_connect(opts, state, proc):
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM, 0)
    s.connect(opts.config.get("xmpp", "dmproc"))
    helpers.send_frame(s, proc)
    status = helpers.recv_frame(s)
    if (status == "status 0;"):
        t = threading.Thread(target=dmproc_consume, args=(state,))
        state["dmproc"] = (s, t)
        t.start()
        return(0)
    else:
        return(1)

def dmproc_consume(state):
    s = state.get("dmproc")[0]
    while ("dmproc" in state):
        r = select.select([s.fileno()], [], [], 1)[0]
        if (len(r) == 1):
            frame = helpers.recv_frame(s)
            if (frame is None):
                break
            else:
                dump(__stdout__, make_events_relative(frame))
    dump(__stdout__, "\n")

def dmproc_disconnect(opts, state):
    helpers.send_frame(state["dmproc"][0], "close;")
    state["dmproc"][1].join()
    del(state["dmproc"])
    return(0)

def invoke(f, state={}):
    def g(opts, cmd, **kwargs):
        rc = f(opts, state, **kwargs)
        dump(__stderr__, "%s: %d" % (cmd, rc), "\n")
        return(rc)
    return(g)

def run_script(opts, script):
    state  = {}
    rc     = 0
    engine = {"initd-start": invoke(initd_start),
              "initd-stop": invoke(initd_stop),
              "initd-restart": invoke(initd_restart),
              "echo": invoke(echo),
              "sleep": invoke(sleep),
              "cassandra-truncate": invoke(cassandra_truncate),
              "udp-send": invoke(udp_send),
              "http-request": invoke(http_request),
              "dmproc-connect": invoke(dmproc_connect, state),
              "dmproc-disconnect": invoke(dmproc_disconnect, state)
             }
    for (cmd, args) in map(split, script.splitlines()):
        if (cmd.startswith("#")):
            continue
        rc |= engine[cmd](opts, cmd, **args)
    return(rc)

if (__name__ == "__main__"):
    args = argparse.ArgumentParser()
    args.add_argument("--chdir",
                      dest     = "chdir",
                      default  = os.environ.get("CHDIR"),
                      help     = "The root dir you installed leela onto [default: %(default)s]")
    args.add_argument("--config",
                      dest     = "config",
                      default  = config.default_config_file(),
                      help     = "The leela config file to parse and use [default: %(default)s]")
    opts = args.parse_args()
    opts.config = config.read_config(opts.config)
    try:
        sys.exit(run_script(opts, __stdin__.read()))
    except Exception, e:
        dump(__stderr__, traceback.format_exc())
        sys.exit(-1)
