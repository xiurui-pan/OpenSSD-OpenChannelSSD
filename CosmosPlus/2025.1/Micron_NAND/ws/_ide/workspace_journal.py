# 2025-07-17T19:00:32.020890600
import vitis

client = vitis.create_client()
client.set_workspace(path="ws")

comp = client.get_component(name="run-gftl3")
status = comp.clean()

status = comp.clean()

vitis.dispose()

