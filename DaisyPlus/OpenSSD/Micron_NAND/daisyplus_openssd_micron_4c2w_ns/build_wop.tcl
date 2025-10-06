open_project cosm-plus-sys/cosm-plus-sys.xpr
report_ip_status -name wop_ip_report
upgrade_ip [get_ips]
launch_runs synth_1
wait_on_run synth_1
