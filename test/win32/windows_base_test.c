#include <stdio.h>

#include "win32/windows_base.h"
#include "win32/Zig/zig_bridge.h"

int main(void) {
	printf("Win32 windows_base.h ABI validation:\n");
	rosette_print_abi_report();

	int rc = rosette_validate_abi();
	if (rc == 0) {
		printf("windows_base ABI validation: OK\n");
	} else {
		printf("windows_base ABI validation: FAIL (code %d, %s)\n",
			   rc, rosette_abi_failure_name(rc));
	}
	return rc;
}
