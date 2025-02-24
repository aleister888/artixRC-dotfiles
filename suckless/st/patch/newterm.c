extern char* argv0;

static char*
getcwd_by_pid(pid_t pid) {
	static char cwd[32];
	snprintf(cwd, sizeof cwd, "/proc/%d/cwd", pid);
	return cwd;
}

void
newterm(const Arg* a)
{
	switch (fork()) {
	case -1:
		die("fork failed: %s\n", strerror(errno));
		break;
	case 0:
		switch (fork()) {
		case -1:
			die("fork failed: %s\n", strerror(errno));
			break;
		case 0:
			chdir(getcwd_by_pid(pid));

			execl("/proc/self/exe", argv0, NULL);
			exit(1);
		default:
			exit(0);
		}
	}
}
