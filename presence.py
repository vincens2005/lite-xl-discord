#!/usr/bin/python3
# you need to have pypresence installed for this to work
import time
import pickle
import os
import json
from pypresence import Presence

discord_data = {
    "state": "...",
    "details": "loading lite-xl plugin",
    "die_now": "no"
}
waiting = False


def load_data(cur_dat):
    fp = open("discord_data.pickle", "rb")
    data = pickle.load(fp)
    data = json.loads(data)
    if data["die_now"] != "no":
        exit()
    if data != cur_dat:
        print("got new data!")
        print(data)
        return data
    else:
        print("data is the same :(")
        print(data)
        return cur_dat


def reset_data(data):
    data = json.dumps(data)
    fp = open("discord_data.pickle", "wb")
    pickle.dump(data, fp,)
    fp.close()


# discord client id:
client_id = "839231973289492541"
rpc = Presence(client_id)
print("connecting to rpc...")
rpc.connect()
start_time = time.time()
rpc.update(start=start_time, state="loading discord plugin", large_image="lite-xl")

reset_data(discord_data)

while True:
    print("current discord dta:", discord_data)
    discord_data = load_data(discord_data)
    rpc.update(
        pid=os.getpid(),
        start=start_time,
        state=discord_data["state"],
        details=discord_data["details"],
        large_image="lite-xl"
    )
    time.sleep(15)  # discord sleep timeout
