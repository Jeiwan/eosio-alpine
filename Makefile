build:
	docker build -t eosio-alpine .

run:
	docker run --rm -it eosio-alpine keosd