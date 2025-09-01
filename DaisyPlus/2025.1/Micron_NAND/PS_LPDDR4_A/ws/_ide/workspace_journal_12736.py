# 2025-07-16T16:24:00.293217
import vitis

client = vitis.create_client()
client.set_workspace(path="daisyplus_openssd_micron")

advanced_options = client.create_advanced_options_dict(dt_overlay="0")

platform = client.create_platform_component(name = "daisyplus",hw_design = "$COMPONENT_LOCATION/../../../DaisyPlus/2025.1/daisyplus_openssd_micron_4c2w_66mhz_20251_20250708/sys_top_wrapper.xsa",os = "standalone",cpu = "psu_cortexa53_0",domain_name = "standalone_psu_cortexa53_0",generate_dtb = False,advanced_options = advanced_options,architecture = "64-bit",compiler = "gcc")

platform = client.get_component(name="daisyplus")
status = platform.build()

status = platform.build()

comp = client.create_app_component(name="run-gr3ftl",platform = "$COMPONENT_LOCATION/../daisyplus/export/daisyplus/daisyplus.xpfm",domain = "standalone_psu_cortexa53_0")

status = platform.build()

comp = client.get_component(name="run-gr3ftl")
comp.build()

status = platform.build()

comp.build()

comp = client.get_component(name="run-gr3ftl")
status = comp.import_files(from_loc="$COMPONENT_LOCATION/../../../DaisyPlus/2025.1/daisyplus_openssd_micron_4c2w_66mhz_20251_20250708/cosm-plus-sys.sdk", files=["run-gr3ftl"], dest_dir_in_cmp = "src")

status = platform.build()

comp = client.get_component(name="run-gr3ftl")
comp.build()

status = platform.build()

comp.build()

comp = client.get_component(name="run-gr3ftl")
status = comp.import_files(from_loc="$COMPONENT_LOCATION/src", files=[".clangd", "address_translation.c", "address_translation.h", "app.yaml", "CMakeLists.txt", "compile_commands.json", "data_buffer.c", "data_buffer.h", "Empty_applicationExample.cmake", "ftl_config.c", "ftl_config.h", "garbage_collection.c", "garbage_collection.h", "lscript.ld", "main.c", "memory_map.h", "nsc_driver.c", "nsc_driver.h", "README.txt", "request_allocation.c", "request_allocation.h", "request_format.h", "request_queue.h", "request_schedule.c", "request_schedule.h", "request_transform.c", "request_transform.h", "t4nsc_pm.h", "t4nsc_ucode.h", "UserConfig.cmake"], dest_dir_in_cmp = "nvme")

status = platform.build()

comp = client.get_component(name="run-gr3ftl")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

domain = platform.get_domain(name="standalone_psu_cortexa53_0")

status = domain.set_config(option = "lib", param = "XILTIMER_en_interval_timer", value = "true", lib_name="xiltimer")

status = platform.build()

comp.build()

status = platform.build()

comp.build()

comp = client.create_app_component(name="memory_tests",platform = "$COMPONENT_LOCATION/../daisyplus/export/daisyplus/daisyplus.xpfm",domain = "standalone_psu_cortexa53_0",template = "memory_tests")

status = platform.build()

comp = client.get_component(name="memory_tests")
comp.build()

client.delete_component(name="memory_tests")

status = platform.build()

comp = client.get_component(name="run-gr3ftl")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

vitis.dispose()

