#if RR_ENABLED
int rr_dep_value(void);
#endif

int rr_host_value(void)
{
#if RR_ENABLED
	return rr_dep_value();
#else
	return 17;
#endif
}
