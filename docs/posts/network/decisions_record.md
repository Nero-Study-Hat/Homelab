# Decisions Record

#### Moving my Homelab over to a new and separate domain for my private infrastructure.
- reasoning
	- Cloudflare Proxy which I want to use is only available with the Full-DNS setup on the free tier where they must be the nameserver in control of the domain.
	- I want to keep Dessec for my private infrastructure and only use Cloudflare for the public infrastructure.
- plan
	- I will use the main domain name of `neolabs` with the TLD changing per year (take adv of first time buy discount) until I have enough money that I don't feel the need to be cheap here.
	- That means the first years will be something like
	- year 1: `neolabs.cloud` which is not the cheapest but still under $4 dollars so fine enough
	- year 2: `neolabs.one` which is under $2 cheap and has a nice meaning regarding neo that I like
	- year 3: `neolabs.art` which is under $2 cheap and I like art
	- past year 3: by this point I should be able to comfortably afford a consistent `.dev` or some such domain, potentially earlier but best to plan long-game