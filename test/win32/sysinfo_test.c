#include <stdio.h>

#include "win32/sysinfo.h"
#include "win32/Zig/zig_bridge.h"

int main(void) {
	printf("Win32 sysinfo.h ABI validation:\n");
	rosette_print_sysinfo_report();

	int rc = rosette_validate_sysinfo();
	if (rc == 0) {
		printf("sysinfo ABI validation: OK\n");
	} else {
		printf("sysinfo ABI validation: FAIL (code %d, %s)\n",
			   rc, rosette_sysinfo_failure_name(rc));
	}
	return rc;
}
