# 2025-07-17T10:03:07.353037
import vitis

client = vitis.create_client()
client.set_workspace(path="daisyplus_openssd_micron")

platform = client.get_component(name="daisyplus")
status = platform.build()

comp = client.get_component(name="run-gr3ftl")
comp.build()

vitis.dispose()

