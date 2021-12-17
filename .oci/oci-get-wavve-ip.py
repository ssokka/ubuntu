# -*- coding: utf-8 -*-

import os, sys, oci, socket, time, json
from datetime import datetime
from time import sleep
from random import randrange
from discord_webhook import DiscordWebhook, DiscordEmbed

SERVER_NAME = socket.gethostname().upper()
# SERVER_NAME = ""  # 서버명 수동 입력

PROFILE = "DEFAULT"
WEBHOOK = ""

for i in range(1, len(sys.argv)):
    if i == 1: PROFILE = sys.argv[1]
    if i == 2: WEBHOOK = sys.argv[2]

# wait unit : seconds
WAIT_MIN = 15
WAIT_MAX = 30

SCRIPT_PATH = sys.argv[0]
PID = os.getpid()
SUCCEED = False
TIMESTAMP = ""
MSG_QUEUE = []
START_TIME = time.time()

def log(msg):
    global TIMESTAMP
    TIMESTAMP = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print("{}|{}|{}|{}|{}".format(TIMESTAMP, SCRIPT_PATH, PID, PROFILE, msg))

def send_discord():
    try:
        color = "C00000"
        if SUCCEED: color = "0070C0"
        
        webhook = DiscordWebhook(url=WEBHOOK)
        
        description="Get OCI Wavve Reserved Public IP Address\nScript: {}".format(SCRIPT_PATH)
        embed = DiscordEmbed(title=SERVER_NAME, description=description, color=color)
        
        _ps = "".join([x[0]+"/"+x[1] for x in MSG_QUEUE])
        _in = "".join([x[2]+"/"+x[3] for x in MSG_QUEUE])
        _et = "".join([x[4] for x in MSG_QUEUE])
        
        embed.add_embed_field(name="Profile/Status", value=_ps)
        embed.add_embed_field(name="IP/Name", value=_in)
        embed.add_embed_field(name="ElapsedTime", value=_et)
        embed.add_embed_field(name="TimeStamp", value=TIMESTAMP, inline=False)
        
        embed.set_timestamp()
        webhook.add_embed(embed)
        response = webhook.execute()
        # print(response)
    except Exception as e:
        pass

# main

log("*** Start ***")

try:
    config = oci.config.from_file("~/.oci/config", PROFILE)
    vnc = oci.core.VirtualNetworkClient(config)
except Exception as e:
    log("Error|{}".format(e))
    sys.exit()

while True:
    try:
        log("Create")
        create = vnc.create_public_ip(
            oci.core.models.CreatePublicIpDetails(
                compartment_id = config["tenancy"],
                lifetime = 'RESERVED'
            ), retry_strategy = oci.retry.DEFAULT_RETRY_STRATEGY
        ).data
        if "140.238." in create.ip_address or "132.145." in create.ip_address:
            log("{}|{}".format(status,create.ip_address))
            SUCCEED = True
            status = "Succeed"
            ip_address = create.ip_address
            display_name = "publicip"
            update = vnc.update_public_ip(
                create.id,
                oci.core.models.UpdatePublicIpDetails(
                    display_name = display_name
                ), retry_strategy = oci.retry.DEFAULT_RETRY_STRATEGY
            )
            log("Update display name|{}".format(display_name))
            break
        else:
            log("Failed|{}".format(create.ip_address))
            while True:
                try:
                    log("Delete|{}".format(create.ip_address))
                    delete = vnc.delete_public_ip(
                        create.id,
                        retry_strategy = oci.retry.DEFAULT_RETRY_STRATEGY
                    )
                except:
                    continue
                break
    except Exception as e:
        log("Error|{}".format(e))
        status = e.code
        ip_address = "none"
        display_name = "none"
        if e.code == "TooManyRequests":
            pass
        else:
            break
    wait = randrange(WAIT_MIN, WAIT_MAX)
    log("Wait|{}s".format(wait))
    sleep(wait)

elapsed_time = time.strftime("%H:%M:%S",time.gmtime(time.time()-START_TIME))
MSG_QUEUE.append([PROFILE, status, ip_address, display_name, elapsed_time])
send_discord()

log("*** End ***")

sys.exit()
