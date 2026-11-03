int rr_host_value(void);

int main(void)
{
	return rr_host_value() == RR_EXPECTED ? 0 : 1;
}
