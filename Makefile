report_pattern = src/
report_file = luacov.report.out

.PHONY: clean test stats view_report

clean:
	-@rm $(report_file)
	-@rm luacov.stats.out

test:
	@lua test/test_utils.lua

stats: clean
	@lua -lluacov test/test_utils.lua > /dev/null

report: stats
	luacov $(report_pattern)

report_test: report
	# exit 0 if we find no instances of untested lines in the report file
	@! grep --fixed-strings "***0" $(report_file) > /dev/null

view_report: report
	nvim $(report_file)

release_test: test report_test
