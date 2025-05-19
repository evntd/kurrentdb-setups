# Setup KurrentDB as secure single node

This was built for `Ubuntu-24.04` so your milage may vary. There are some notes for Microsoft and Apple users for installing certificates.

Run securely from the start. This differs from the [setup provided by Kurrent](https://github.com/kurrent-io/KurrentDB/blob/master/docker-compose.yml). 
The folder structure differs, and file permissions are tighten a tad bit, and a path to changing the default admin and ops passwords is ready to go.

Here's how the folder structure should look after completing the setup.

```
YOUR-PROJECT/
├─ .kurrent/
|  ├─ entrypoint.sh
|  ├─ root/
|  |  ├─ ca/
|  |  |  ├─ ca.crt
|  |  |  ├─ ca.key
|  ├─ node1/
|  |  ├─ cert/
|  |  |  ├─ node.crt
|  |  |  ├─ node.key
|  |  ├─ data/
|  |  |  ├─ (kurrent db data)
|  |  ├─ logs/
|  |  |  ├─ (kurrent db logs)
|  ├─ secrets/
|  |  ├─ default_admin_password
|  |  ├─ default_ops_password 
```

Copy `./secure-single` to your project location.

#### Certificate setup for encryption in-flight 

```shell
# Generate the certificate authority (CA) certificate and private key
docker run --rm -e PROVISION_DIRECTORIES="1000:1000:0755:/tmp/root" -v "$(pwd)/.kurrent/root:/tmp/root" hasnat/volumes-provisioner
docker run --rm -u 1000:1000 -v "$(pwd)/.kurrent/root:/certs" --entrypoint bash eventstore/es-gencert-cli:1.0.2 \
  -c "mkdir -p /certs && cd /certs && es-gencert-cli create-ca \
      && chmod 600 ca/ca.key \
      && chmod 644 ca/ca.crt"

# Generate the certificate and private key for node1
docker run --rm -e PROVISION_DIRECTORIES="1000:1000:0755:/tmp/node1" -v "$(pwd)/.kurrent/node1:/tmp/node1" hasnat/volumes-provisioner
docker run --rm -e PROVISION_DIRECTORIES="1000:1000:0700:/tmp/node1/data /tmp/node1/logs" -v "$(pwd)/.kurrent/node1:/tmp/node1" hasnat/volumes-provisioner
docker run --rm -u 1000:1000 -v "$(pwd)/.kurrent/node1:/certs" -v "$(pwd)/.kurrent/root/ca:/certs/ca" --entrypoint bash eventstore/es-gencert-cli:1.0.2 \
  -c "mkdir -p /certs && cd /certs && es-gencert-cli create-node -out ./cert -ip-addresses 127.0.0.1,172.30.240.11 -dns-names localhost \
      && chmod 600 cert/node.key \
      && chmod 644 cert/node.crt"

# (Optional) Remove the empty ca folder from extra volume mount       
rmdir "$(pwd)/.kurrent/node1/ca"
      
# Update the trusted certificates on the local machine
# This is needed to run YOUR-PROJECT, otherwise the local machine rejects the certificate KurrentDB presents
sudo cp "$(pwd)/.kurrent/root/ca/ca.crt" /usr/local/share/ca-certificates
sudo update-ca-certificates
```

---

### 🪟 For Windows Users

Use PowerShell to import the certificate.

```powershell
Import-Certificate -FilePath .kurrent/root/ca/ca.crt -CertStoreLocation Cert:\LocalMachine\Root
```

---

### 🍎 For OSX Users

I've never been a Mac user, so this very well could be flat out wrong. 

```
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain .kurrent/root/ca/ca.crt
```

⚠️ If you're running on Apple Silicon, you'll likely need to use the ARM image which is still experimental. 

```
kurrentplatform/kurrentdb:25.0.0-experimental-arm64-8.0-jammy
```

---

#### Configure browser 

To avoid warnings when using Kurrent Navigator or the Legacy UI, you'll likely need to import `.kurrent/root/ca/ca.crt` 
into the browser. For Chrome, go to `chrome://certificate-manager/localcerts/usercerts`.

#### Change the default passwords

The default password for both `admin` and `ops` users is `changeit`. This is a pretty direct hint that something
should be done about this.

Put your desired initial passwords in `.kurrent/secrets/default_admin_password` and `.kurrent/secrets/default_ops_password`.
These paths have been configured as secrets within docker compose, and are ignored by git.

```shell
echo "changeit_again!" > .kurrent/secrets/default_admin_password
echo "really_changeit" > .kurrent/secrets/default_ops_password 
```

## Fire up the engine!

```shell
docker compose up -d
```

Crack open the browser and go to `https://localhost:2113`

