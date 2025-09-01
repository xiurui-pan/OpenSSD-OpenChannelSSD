# 2025-07-17T17:33:03.284208300
import vitis

client = vitis.create_client()
client.set_workspace(path="ws")

comp = client.get_component(name="run-gr3ftl")
status = comp.clean()

status = comp.clean()

status = comp.clean()

vitis.dispose()

