#!/usr/bin/python3
# you need to have pypresence installed for this to work
import time
import pickle
import os
import json
import argparse
from pypresence import Presence

discord_data = {
    "state": "...",
    "details": "loading discord plugin",
    "die_now": "no"
}
waiting = False


parser = argparse.ArgumentParser()
parser.add_argument("--pickle", dest="pickle")
args = parser.parse_args()


current_pid = str(os.getpid())
pidfile = "presence_py.pid"

if os.path.isfile(pidfile):
    print("other instance is running. I will go commit die.")
    exit()
open(pidfile, 'w').write(current_pid)  # write pid to file


def load_data(cur_dat, pickle_file):
    fp = open(pickle_file, "rb")
    data = pickle.load(fp)
    data = json.loads(data)
    if data["die_now"] != "no":
        os.unlink(pidfile)  # delete file before killing self
        exit()
    if data != cur_dat:
        print("got new data!")
        print(data)
        return data
    else:
        print("data is the same :(")
        print(data)
        return cur_dat


def reset_data(data, pickle_file):
    data = json.dumps(data)
    fp = open(pickle_file, "wb")
    pickle.dump(data, fp,)
    fp.close()


try:
    # discord client id:
    client_id = "839231973289492541"
    rpc = Presence(client_id)
    print("connecting to rpc...")
    rpc.connect()
    start_time = time.time()
    rpc.update(start=start_time, state="loading discord plugin", large_image="lite-xl")
    
    reset_data(discord_data, args.pickle)
    
    while True:
        print("current discord dta:", discord_data)
        discord_data = load_data(discord_data, args.pickle)
        rpc.update(
            pid=os.getpid(),
            start=start_time,
            state=discord_data["state"],
            details=discord_data["details"],
            large_image="lite-xl"
        )
        time.sleep(15)  # discord sleep timeout
finally:
    os.unlink(pidfile)  # delete pidfile if crash happens
