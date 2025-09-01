# 2025-09-01T13:11:26.663089100
import vitis

client = vitis.create_client()
client.set_workspace(path="ws2")

comp = client.get_component(name="ftl")
status = comp.clean()

status = comp.clean()

status = comp.clean()

status = comp.clean()

status = comp.clean()

status = comp.clean()

platform = client.get_component(name="daisyplus")
status = platform.build()

vitis.dispose()

