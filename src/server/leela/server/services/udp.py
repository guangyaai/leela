#!/usr/bin/python
# -*- coding: utf-8; -*-
#
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

from twisted.internet import reactor
from twisted.application.service import Service
from leela.server import logger
from leela.server.network import udp_proto
from leela.server.network import databus

def x(*args):
    print(args)

class RoundRobin(object):

    def __init__(self, ring):
        self.ring = ring

    def getnext(self):
        x = self.ring.pop(0)
        self.ring.append(x)
        return(x)

class UdpService(Service, udp_proto.UDP):

    def mkbus(self, string):
        result = []
        for group in string.split(","):
            tmp = map(lambda s: s.strip(), group.split(";"))
            logger.warn("creating new broadcast group (RR): " + ", ".join(tmp))
            result.append(RoundRobin(map(lambda f: databus.connect_to(f), tmp)))
        return(result)

    def __init__(self, cfg):
        self.cfg = cfg
        self.bus = self.mkbus(cfg.get("udp", "broadcast"))

    def broadcast(self, events):
        for rr in self.bus:
            rr.getnext().send_broadcast(events)

    def recv_event(self, events):
        logger.debug("recv_events: %d" % len(events))
        self.broadcast(events)

    def startService(self):
        reactor.listenUDP(self.cfg.getint("udp", "port"), self, self.cfg.get("udp", "address"))
