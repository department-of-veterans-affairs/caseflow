#! /bin/bash

# Some commands on Travis randomly flake out. To protect against this,
# we'll retry them a small number of times until they succeed.

for i in {1..5}
do
  eval $@ && break
  sleep 1
done
