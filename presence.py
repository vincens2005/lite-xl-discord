from pypresence import Presence
import time
from lua_imports import lua_importer

lua_importer.register()

import fake_thingy

client_id = "839231973289492541"
rpc = Presence(client_id)
rpc.connect()
start_time = time.time()

while True:
    data = fake_thingy.get_data()
    print(data.doc_title)
    rpc.update(
        start=start_time,
        state="editing file "+data.doc_title,
        large_image="lite-xl"
    )
    time.sleep(15)
