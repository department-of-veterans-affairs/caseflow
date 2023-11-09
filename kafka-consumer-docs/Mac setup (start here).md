## pre-reqs

1. Homebrew (installed through the Self Service app)
2. Command Line Tools (installed through the Self Service app)

## clone the repo

Create a `~/dev/appeals/` directory

Clone the following repo using git clone into this directory

 - `< REPLACE WITH LINK TO REPO >`

> If you cannot clone the above, you might need to do [this setup](https://docs.github.com/en/enterprise-server@3.4/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)

## installing postgresql

if you haven't already install postgres, you can do so using Homebrew:
`brew install postgresql`

## Installing Ruby v3.2.2

We will be using `rbenv` to manage the Ruby version for this application. You can install rbenv using Homebrew:

`brew install rbenv ruby-build`

<details>
<summary>Intell Only</summary>
For Macs with Intel processors, you can install Ruby v3.2.2 using rbenv directly:

`rbenv install 3.2.2`
</details>

<details>
<summary>M1 & M2 Only</summary>
For the newer Macs with Arm64 processors, we will need to compile and build Ruby separately. You can do this with the `./scripts/ruby-install.sh` script. The steps of the script are described in the `./M1_Ruby_install.md` file.
</details>

run `rbenv rehash` to ensure that the shims have been added correctly.

After Ruby is installed, you can `cd` into the project directory and check that you have the correct ruby version with `ruby -v`. Additionally, you should see version 3.2.2 listed when you run `rbenv versions`.
## Project dependencies and setup DB

From the project directory, run:

```bash
bundle
rails db:setup
```




