#!/usr/bin/env bash
# referenced guide: https://www.czeskis.com/random/openssl-encrypt-file.html

# 12/17/24
# I enjoyed my research for this and find what I have put together here cool
# but after reviewing this, thinking more, and doing more research I have
# found that this whole thing should be scrapped without getting used and
# I should just use age as that
# - allows me to use ed25519 for encryption
# - has its algorithms chosen by people much more knowledge here than me
# - is very simple to work with meaning an easier time extending a script using it and avoiding foot guns
# - no extra files key.bin sshkey.pem sshkey.pub.pem are needed

# the key.bin contents are stored in the 

key_name="pve-terra-test"
sshkey="$HOME/.ssh/${key_name}"

tmp_dir="$HOME/.ssh/tmp"
enc_keybin="$PWD/key.bin.enc"
dec_keybin="${tmp_dir}/key.bin"

plain_file="terraform.tfstate"
encrypted_file="terraform.tfstate.enc"

mkdir -p "$tmp_dir"

#TODO: check if these files already exist
# every terraform apply case beginning
openssl rsa -in "$sshkey" -outform pem > "${tmp_dir}/${key_name}.pem"
openssl rsa -in "$sshkey" -pubout -outform pem > "${tmp_dir}/${key_name}.pub.pem"
openssl pkeyutl -decrypt -inkey "${tmp_dir}/${key_name}.pem" -in "$enc_keybin" -out "$dec_keybin"

# terraform apply with -> no existing state file or an existing unencrypted state file
function only_encrypt {
    terraform apply
    openssl enc -aes-256-ecb -pbkdf2 -in "terraform.tfstate" -out "terraform.tfstate.enc" -pass "file:${$dec_keybin}"
    shred -zu "$plain_file"
}

# terraform apply with -> an existing encrypted state file
function decrypt_encrypt {
    openssl enc -d -aes-256-ecb -pbkdf2 -in "terraform.tfstate.enc" -out "dec_terraform.tfstate" -pass "file:${$dec_keybin}"
    shred -zu "$encrypted_file"
    terraform apply
    openssl enc -aes-256-ecb -pbkdf2 -in "terraform.tfstate" -out "terraform.tfstate.enc" -pass "file:${$dec_keybin}"
    shred -zu "$plain_file"
}

if [ -f "./terraform.tfstate" ] || [[ ! -f "./terraform.tfstate" && ! -f "./terraform.tfstate.crypt" ]]; then
    only_encrypt
elif [ -f "./terraform.tfstate.crypt" ]; then
    decrypt_encrypt
fi

# TODO: prompt to shred or not
shred -zu "${tmp_dir}/${key_name}.pem" "${tmp_dir}/${key_name}.pub.pem" "$dec_keybin"
rmdir "$tmp_dir"



### This was the first complete version of this script which couldn't handle the file size.
#!/usr/bin/env bash
# referenced gist: https://gist.github.com/phrfpeixoto/8b04a2516ec559eddbfe7520ddde9ad2

# the sshkey pair used for this is the same used by ansible in this project
# which is storied with sops in the /terraform/secrets/secrets.yaml file

sshkey_name="pve-terra-test"
sshkey_dir="$HOME/.ssh"
priv_sshkey="${sshkey_dir}/${sshkey_name}"
pub_sshkey="${priv_sshkey}.pub"

plain_file="terraform.tfstate"
encrypted_file="terraform.tfstate.crypt"

# every terraform apply case beginning
cp "$priv_sshkey" "./" && ssh-keygen -f "./${sshkey_name}" -m pem -p
ssh-keygen -f "$pub_sshkey" -e -m PKCS8 > "${sshkey_name}.pem.pub"

# terraform apply with -> no existing state file or an existing unencrypted state file
function only_encrypt {
    terraform apply
    openssl pkeyutl -encrypt -pubin -inkey "${sshkey_name}.pem.pub" -in "$plain_file" -out "$encrypted_file"
    rm "$plain_file"
}

# terraform apply with -> an existing encrypted state file
function decrypt_encrypt {
    openssl pkeyutl -decrypt -inkey "./${sshkey_name}" -in "$encrypted_file" -out "$plain_file"
    rm "$encrypted_file"
    terraform apply
    openssl pkeyutl -encrypt -pubin -inkey "${sshkey_name}.pem.pub" -in "$plain_file" -out "$encrypted_file"
    rm "$plain_file"
}

if [ -f "./terraform.tfstate" ] || [[ ! -f "./terraform.tfstate" && ! -f "./terraform.tfstate.crypt" ]]; then
    only_encrypt
elif [ -f "./terraform.tfstate.crypt" ]; then
    decrypt_encrypt
fi

rm "./${sshkey_name}" "./${sshkey_name}.pem.pub"