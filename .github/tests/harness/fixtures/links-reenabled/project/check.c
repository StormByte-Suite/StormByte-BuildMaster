int rr_host_value(void);

int main(void)
{
	return rr_host_value() == 42 ? 0 : 1;
}
