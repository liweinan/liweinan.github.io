---
title: How To Use Tomcat Vault
abstract: Tomcat Vault is a tool that allows you to encrypt the passwords in Apache Tomcat configuration files. In this article I'd like to show you how to integrate it into Apache Tomcat.
---

{{ page.abstract }}

Here is one line excerpted from `tomcat-users.xml`:

```xml
<user username="tomcat" password="tomcat" roles="tomcat"/>
```

As we can see above, the password is stored as plaintext and it's a security risk. Though the configuration in store on server, it's still very dangerous to store password in such way.

Tomcat Vault is created to solve this problem, it will encrypt your password and store it in standard Java keystore, and let tomcat access the password in a safe way. In this article, I'd like to show you how to use it with Tomcat.

### Installation of Apache Tomcat and Tomcat Vault

First we need to have Apache Tomcat[^1] and Tomcat-Vault[^2] installed on our machine. For Tomcat, I am using 8.0.39 for this article. For Tomcat Vault, I just clone the project from GitHub into my local machine and build it from master branch:

```bash
git clone https://github.com/picketbox/tomcat-vault.git
```

And then using Maven to build and install it:

```bash
$ pwd
/Users/weli/projs/tomcat-vault
$ mvn install
[INFO] Scanning for projects...
[INFO]
[INFO] ------------------------------------------------------------------------
[INFO] Building Vault extension for Apache Tomcat 1.0.8.Final
[INFO] ------------------------------------------------------------------------
[INFO]
...
copy dependency file to the correct module directory:
     [copy] Copying 1 file to /Users/weli/projs/tomcat-vault/modules/system/layers/base/tomcat-vault/main
[INFO] Executed tasks
[INFO]
[INFO] --- maven-install-plugin:2.4:install (default-install) @ tomcat-vault ---
[INFO] Installing /Users/weli/projs/tomcat-vault/target/tomcat-vault-1.0.8.Final.jar to /Users/weli/.m2/repository/org/apache/tomcat/tomcat-vault/1.0.8.Final/tomcat-vault-1.0.8.Final.jar
[INFO] Installing /Users/weli/projs/tomcat-vault/pom.xml to /Users/weli/.m2/repository/org/apache/tomcat/tomcat-vault/1.0.8.Final/tomcat-vault-1.0.8.Final.pom
[INFO] Installing /Users/weli/projs/tomcat-vault/target/tomcat-vault-1.0.8.Final-jar-with-dependencies.jar to /Users/weli/.m2/repository/org/apache/tomcat/tomcat-vault/1.0.8.Final/tomcat-vault-1.0.8.Final-jar-with-dependencies.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 2.567 s
[INFO] Finished at: 2016-12-20T16:34:53+08:00
[INFO] Final Memory: 17M/265M
[INFO] ------------------------------------------------------------------------
```

After building it, we can get the tomcat-vault jars:

```bash
$ ls -1 target/*.jar
target/tomcat-vault-1.0.8.Final-jar-with-dependencies.jar
target/tomcat-vault-1.0.8.Final.jar
```

Next we will can try to play with `tomcat-vault-1.0.8.Final-jar-with-dependencies.jar` to see if it can work correctly. First we should make sure that we are in the 'target' directory which contains the generated jar files:

```bash
$ pwd
/Users/weli/projs/tomcat-vault/target
$ ls *.jar
tomcat-vault-1.0.8.Final-jar-with-dependencies.jar tomcat-vault-1.0.8.Final.jar
```

Because the jar file contains a Main class, so we can invoke it like this:

```bash
$ java -classpath tomcat-vault-1.0.8.Final-jar-with-dependencies.jar org.apache.tomcat.vault.VaultTool
**********************************
****  JBoss Vault  ***************
**********************************
Please enter a Digit::   0: Start Interactive Session  1: Remove Interactive Session  2: Exit
```

If everything goes fine, you can directly using the `java` command as shown above to start the `org.apache.tomcat.vault.VaultTool`. The next step is to put tomcat-vault jar into our local Apache Tomcat directory:

```bash
$ pwd
/Users/weli/projs/apache-tomcat-8.0.39/lib
$ cp ~/projs/tomcat-vault/target/tomcat-vault-1.0.8.Final-jar-with-dependencies.jar .
```

As the command shown above, we have the tomcat-vault jar with dependecies copied into tomcat lib directory. Till now, the installation step is finished, and next we can start to integrate tomcat-vault with tomcat.

### Generating Java Keystore for Tomcat Vault

Tomcat Vault relies on Java Keystore to store the passwords, so the first step is to use `keytool` command provided by JDK to generate a keystore. Here is the command to generate keystore:

```bash
$ keytool -genseckey -keystore vault.keystore -alias my_vault -storetype jceks -keyalg AES -keysize 128 -storepass my_password123 -keypass my_password123 -validity 730
```

As the command shown above, we have generated a keystore named `vault.keystore`, and set the password of the store to `my_password123`. We also generate a key pair with the `alias` name `my_vault`, and set the password of this generated key pair to `my_password123` (You should use different password for key store and key pair in production environment). Please note that I have put the above generated keystore file to `conf` directory of Tomcat:

```bash
$ pwd
/Users/weli/projs/apache-tomcat-8.0.39/conf
$ ls vault.keystore
vault.keystore
```

In production environment, you should put the keystore into a safer place and set the permission of the file properly. Now we can check this keystore by using the `keytool` command:

```bash
$ keytool -list -v -keystore vault.keystore -storetype jceks -storepass my_password123

Keystore type: JCEKS
Keystore provider: SunJCE

Your keystore contains 1 entry

Alias name: my_vault
Creation date: Dec 20, 2016
Entry type: SecretKeyEntry


*******************************************
*******************************************
```

As the command output shown above, we can see our keystore contains one `SecretKeyEntry` named `my_vault`. Till now, we have generated the keystore for tomcat vault to use. The next step is to invoke tomcat vault to initialize the keystore for us.

### Initializing Tomcat Vault

Now we can invoke tomcat vault to initialize the keystore so it can be used to store tomcat username and password information. First we need to go to the `lib` directory of tomcat, because in previous steps we have put tomcat-vault jar into it:

```bash
$ pwd
/Users/weli/projs/apache-tomcat-8.0.39/lib
$ ls tomcat-vault*
tomcat-vault-1.0.8.Final-jar-with-dependencies.jar
```

We need to invoke the above tomcat-vault jar to initialize the keystore we generated in previous step, which is named `vault.keystore`. Here is the whole step to use tomcat-vault to initialize the keystore:

```bash
$ java -classpath tomcat-vault-1.0.8.Final-jar-with-dependencies.jar org.apache.tomcat.vault.VaultTool
**********************************
****  JBoss Vault  ***************
**********************************
Please enter a Digit::   0: Start Interactive Session  1: Remove Interactive Session  2: Exit
0
Starting an interactive session
Enter directory to store encrypted files:/Users/weli/projs/apache-tomcat-8.0.39/conf
Enter Keystore URL:/Users/weli/projs/apache-tomcat-8.0.39/conf/vault.keystore
Enter Keystore password:
Enter Keystore password again:
Values match
Enter 8 character salt:1234abcd
Enter iteration count as a number (Eg: 44):120
Enter Keystore Alias:my_vault
Initializing Vault
Dec 21, 2016 3:43:33 PM org.apache.tomcat.vault.security.vault.PicketBoxSecurityVault init
INFO: PBOX000361: Default Security Vault Implementation Initialized and Ready
Vault Configuration in tomcat properties file:
********************************************
...
KEYSTORE_URL=/Users/weli/projs/apache-tomcat-8.0.39/conf/vault.keystore
KEYSTORE_PASSWORD=MASK-3CuP21KMHn7G6iH/A3YpM/
KEYSTORE_ALIAS=my_vault
SALT=1234abcd
ITERATION_COUNT=120
ENC_FILE_DIR=/Users/weli/projs/apache-tomcat-8.0.39/conf/
...
********************************************
Vault is initialized and ready for use
Handshake with Vault complete
Please enter a Digit::   0: Store a secured attribute  1: Check whether a secured attribute exists  2: Exit
2
```

Above is the whole step to use tomcat-vault to initialize the keystore. Let's see the above process step by step. Here is the explanation:

```bash
Please enter a Digit::   0: Start Interactive Session  1: Remove Interactive Session  2: Exit
0
Starting an interactive session
```

We choose `0` to start an interactive session to initialize keystore with tomcat-vault.

```bash
Enter directory to store encrypted files:/Users/weli/projs/apache-tomcat-8.0.39/conf
```

We have assigned a directory to store tomcat-vault encrypted data file. The data file is used to store username and password information, and it's encrypted by the key pair in the key store.

We will configure tomcat-vault to use `vault.keystore`, and we will also configure tomcat-vault to use the key pair `my_vault` in `vault.keystore` for encryption in following steps.

Let go on seeing the configuration process:

```bash
Enter Keystore URL:/Users/weli/projs/apache-tomcat-8.0.39/conf/vault.keystore
Enter Keystore password: my_password123
Enter Keystore password again: my_password123
Values match
```

Here we enter the keystore password so tomcat-vault can access it and use the key pair inside for data encryption. Let's see the next step:

```bash
Enter 8 character salt:1234abcd
Enter iteration count as a number (Eg: 44):120
Enter Keystore Alias:my_vault
Initializing Vault
```

Here we need to enter 'salt' and 'iteration count' as we like, these two attributes are used by tomcat-vault to encrypt its data file. After all above parameters are set, tomcat-vault will finish the initialization process and output the settings:

```bash
KEYSTORE_URL=/Users/weli/projs/apache-tomcat-8.0.39/conf/vault.keystore
KEYSTORE_PASSWORD=MASK-3CuP21KMHn7G6iH/A3YpM/
KEYSTORE_ALIAS=my_vault
SALT=1234abcd
ITERATION_COUNT=120
ENC_FILE_DIR=/Users/weli/projs/apache-tomcat-8.0.39/conf/
```

We need to store above config into a file. In this article, I put above config into a file named `vault.properties` and put it into `conf` directory of tomcat:

```bash
$ pwd
/Users/weli/projs/apache-tomcat-8.0.39/conf
```

```bash
$ ls vault.properties
vault.properties
```

```bash
$ cat vault.properties
KEYSTORE_URL=../conf/vault.keystore
KEYSTORE_PASSWORD=MASK-3CuP21KMHn7G6iH/A3YpM/
KEYSTORE_ALIAS=my_vault
SALT=1234abcd
ITERATION_COUNT=120
ENC_FILE_DIR=../conf/
```

From the above `ENC_FILE_DIR` setting, we can see the place where tomcat-vault put its data file in. Please note that we can use relative path in `KEYSTORE_URL` and `ENC_FILE_DIR` settings. Now let's check whether the `VAULT.dat` is in position:

```bash
$ pwd
/Users/weli/projs/apache-tomcat-8.0.39/conf
$ ls VAULT.dat
VAULT.dat
```

As the command output shown above, we can see the default name of the data file used by tomcat-vault is `VAULT.dat`. Till now, we have three files generated into `conf` directory:

```bash
$ find . | grep -i vault
./VAULT.dat
./vault.keystore
./vault.properties
```

In production environment, you should put above files into a safer place. Now we have finished initializing tomcat vault, the next step is to configure the tomcat to use the vault.

### Configuring Tomcat To Use Vault

Now we can configure Tomcat to use Tomcat-Vault. For the first step, we need to put one line configuration into `conf/catalina.properties`:

```conf
org.apache.tomcat.util.digester.PROPERTY_SOURCE=org.apache.tomcat.vault.util.PropertySourceVault
```

The `catalina.properties` is a long file, and you can just put the above configuration at the bottom of the file. This will load tomcat-vault into Tomcat during server startup, and it will use `vault.properties` in `conf` directory by default.

Now we will use `tomcat-vault` to generate a manager password for Tomcat. This password will be encrypted by the `SecretKeyEntry` in keystore. We need to find the tomcat-vault jar correctly, and if you follow the steps previously, it should be located in `lib` directory of Tomcat:

```bash
lib/tomcat-vault-1.0.8.Final-jar-with-dependencies.jar
```

Now we can use `java` to run the jar to start tomcat-vault command line interface. Here is the command to do so:

```bash
$ java -classpath lib/tomcat-vault-1.0.8.Final-jar-with-dependencies.jar \
org.apache.tomcat.vault.VaultTool \
--keystore conf/vault.keystore \
--keystore-password my_password123 \
--alias my_vault \
--enc-dir conf/ \
--iteration 120 \
--salt 1234abcd \
--vault-block my_block \
--attribute manager_password \
--sec-attr P@SSW0#D
```

I'm running the above command under the root of tomcat directory, so I can add `lib/` and `conf/` in the filepath so the `VaultTool` can find keystore file and vault data file correctly.

In addition, please see I have requested tomcat-vault to add a password named `manager_password` into vault data, and the value of the password is `P@SSW0#D`. Here is the output result of above command:

```bash
Jan 04, 2017 11:52:33 PM org.apache.tomcat.vault.security.vault.PicketBoxSecurityVault init
INFO: PBOX000361: Default Security Vault Implementation Initialized and Ready
Secured attribute value has been stored in vault.
Please make note of the following:
********************************************
Vault Block:my_block
Attribute Name:manager_password
Shared Key:
Configuration should be done as follows:
VAULT::my_block::manager_password::
********************************************
Vault Configuration in tomcat properties file:
********************************************
...
KEYSTORE_URL=conf/vault.keystore
KEYSTORE_PASSWORD=MASK-3CuP21KMHn7G6iH/A3YpM/
KEYSTORE_ALIAS=my_vault
SALT=1234abcd
ITERATION_COUNT=120
ENC_FILE_DIR=conf/
...
********************************************
```

As the result output shown above, we can now refer to `manager_password` in Tomcat configuration, and it will point to the true password `P@SSW0#D` in `VAULT.dat`. The true password is encrypted by the `SecretKeyEntry` in keystore, and only Tomcat can access it with the masked password `KEYSTORE_PASSWORD` configured in `vault.properties`.

Now let's use the `manager_password` in Tomcat configuration. We can use it as the password of Tomcat user `manager`. The first step is to open `conf/tomcat-users.xml`, and then we can put one line of user data at the bottom of this file:

```xml
<user username="manager" password="${VAULT::my_block::manager_password::}" roles="manager-gui" />
```

As the configuration shown above, we can see the password of `manager` is no longer plaintext, but a reference to the entry in VAULT. Till now, all the configurations are done and we are ready to start the Tomcat server for testing.

### Testing Tomcat-Vault Integration

Now we can start the Tomcat server to test our configuration. Firstly, we need to start the server using the script `startup.sh` in `bin`:

```bash
$ ./startup.sh
Using CATALINA_BASE:   /Users/weli/projs/thoughts-on-jboss-webserver/apache-tomcat-8.0.39
Using CATALINA_HOME:   /Users/weli/projs/thoughts-on-jboss-webserver/apache-tomcat-8.0.39
Using CATALINA_TMPDIR: /Users/weli/projs/thoughts-on-jboss-webserver/apache-tomcat-8.0.39/temp
Using JRE_HOME:        /Library/Java/JavaVirtualMachines/jdk1.8.0_66.jdk/Contents/Home
Using CLASSPATH:       /Users/weli/projs/thoughts-on-jboss-webserver/apache-tomcat-8.0.39/bin/bootstrap.jar:/Users/weli/projs/thoughts-on-jboss-webserver/apache-tomcat-8.0.39/bin/tomcat-juli.jar
Tomcat started.
```

From the above log output we can see Tomcat is started, and now let's check whether tomcat-vault is loaded correctly. We can do a `grep` at `catalian.out` in the `log` directory of Tomcat:

```bash
$ cat catalina.out  | grep -i vault
05-Jan-2017 22:02:39.410 INFO [main] org.apache.tomcat.vault.security.vault.PicketBoxSecurityVault.init PBOX000361: Default Security Vault Implementation Initialized and Ready
```

As the result shown above, we can see tomcat-vault is loaded correctly. The next step to verify that we can use the password stored in `VAULT.dat` for account `manager`. By default the Tomcat server is listening on port `8080`:

```
http://127.0.0.1:8080
```

We can access the URL shown above and get the following page:

![Tomcat Default Page]({{ site.url }}/assets/vault01.png)

As the image shown above, we can see the default homepage of our Tomcat server. There is a button named `Manager App` at top-right of the page, please click it, and the login window will popup:

![Login Page]({{ site.url }}/assets/vault02.png)

We can input `manager` in `Name` field, and in `Password` field we can input `P@SSW0#D` as we set before. If tomcat-vault is working, then Tomcat should accept the password, though it's encrypted and stored in `VAULT.dat`. Let's try it:

![Enter username and password]({{ site.url }}/assets/vault03.png)

The authentication is passed and we entered the manager page:

![Manager Page]({{ site.url }}/assets/vault04.png)

Till now we have gone through all the steps to integrate Tomcat-Vault into Tomcat. I have put a complete tomcat server into this repository, and it contains all the configuration files and keystore files we have used in this article. You can check it out and play with it

[^1]: [http://tomcat.apache.org/](http://tomcat.apache.org/)
[^2]: [https://github.com/picketbox/tomcat-vault](https://github.com/picketbox/tomcat-vault)

### _References_

---
