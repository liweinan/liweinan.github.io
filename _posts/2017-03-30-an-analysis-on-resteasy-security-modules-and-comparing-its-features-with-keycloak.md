---
title: An Analysis On RESTEasy Security Modules And Comparing Its Features With Keycloak
abstract: In this article I'd like to share with you my study on RESTEasy security modules and Keycloak features.
---

{{ page.abstract }}

I haven’t finished all the investigations on this topic, but I’d like to share with you some of my findings till now. Firstly I’d like to give a brief introduction to Keycloak. This project is actually an Single-Sign-On solution. You can compare this project with Apereo CAS[^1]. The protcols that Keycloak supports by default are OpenID[^2] and SAML[^3]. These proctcols are just defining the credential exchanging framework, but Keycloak also provides IdP(Identity Provider)[^4] that can help customers to setup a credential server using Wildfly that can store username/password pairs and act as credentials provider, and Keycloak also provides different adapters to various kinds of clients(Service Provider in SSO concept). On the other hand, the RESTEasy security modules are listed here:

```
$ ls -1
jose-jwt
keystone
login-module-authenticator
resteasy-crypto
resteasy-oauth
skeleton-key-idm
```

I’ll introduce the above modules one by one and refer to Keycloak when necessary.

### jose-jwt

The first one is `jose-jwt`. `jose` is `Javascript Object Signing and Encryption`, and `jws` is `JSON Web Token`[^5]. The `jose-jws` module contains classes to deal with these two encryption modules. Keycloak copied part of these classes into its own project:

```
$ pwd
/Users/weli/projs/keycloak/keycloak-github
```

And here are the classes:

```
$ find . | grep jose
./core/src/main/java/org/keycloak/jose
./core/src/main/java/org/keycloak/jose/jwk
./core/src/main/java/org/keycloak/jose/jwk/JSONWebKeySet.java
./core/src/main/java/org/keycloak/jose/jwk/JWK.java
./core/src/main/java/org/keycloak/jose/jwk/JWKBuilder.java
./core/src/main/java/org/keycloak/jose/jwk/JWKParser.java
./core/src/main/java/org/keycloak/jose/jwk/RSAPublicJWK.java
./core/src/main/java/org/keycloak/jose/jws
./core/src/main/java/org/keycloak/jose/jws/Algorithm.java
./core/src/main/java/org/keycloak/jose/jws/AlgorithmType.java
./core/src/main/java/org/keycloak/jose/jws/crypto
./core/src/main/java/org/keycloak/jose/jws/crypto/HashProvider.java
./core/src/main/java/org/keycloak/jose/jws/crypto/HMACProvider.java
./core/src/main/java/org/keycloak/jose/jws/crypto/RSAProvider.java
./core/src/main/java/org/keycloak/jose/jws/crypto/SignatureProvider.java
./core/src/main/java/org/keycloak/jose/jws/JWSBuilder.java
./core/src/main/java/org/keycloak/jose/jws/JWSHeader.java
./core/src/main/java/org/keycloak/jose/jws/JWSInput.java
./core/src/main/java/org/keycloak/jose/jws/JWSInputException.java
./core/src/test/java/org/keycloak/jose
./core/src/test/java/org/keycloak/jose/HmacTest.java
./core/src/test/java/org/keycloak/jose/JsonWebTokenTest.java
./core/src/test/java/org/keycloak/jose/jwk
./core/src/test/java/org/keycloak/jose/jwk/JWKBuilderTest.java
```

Keycloak doesn't contain `jwt` classes:

```
$ find . | grep jwt
./adapters/oidc/adapter-core/src/test/resources/keycloak-jwt.json
./examples/authz/photoz/photoz-html5-client/src/main/webapp/lib/jwt-decode.min.js
./testsuite/integration-arquillian/test-apps/photoz/photoz-html5-client/src/main/webapp/lib/jwt-decode.min.js
./themes/src/main/resources/theme/base/admin/resources/partials/client-credentials-jwt-key-export.html
./themes/src/main/resources/theme/base/admin/resources/partials/client-credentials-jwt-key-import.html
./themes/src/main/resources/theme/base/admin/resources/partials/client-credentials-jwt.html
```

Here are the contents of RESTEasy `jose-jws` module. The directory is:

```
$ pwd
/Users/weli/projs/resteasy-upstream/security/jose-jwt/src
```

Here are the classes:

```
$ find . | grep -v test
.
./main
./main/java
./main/java/org
./main/java/org/jboss
./main/java/org/jboss/resteasy
./main/java/org/jboss/resteasy/jose
./main/java/org/jboss/resteasy/jose/Base64Url.java
./main/java/org/jboss/resteasy/jose/i18n
./main/java/org/jboss/resteasy/jose/i18n/LogMessages.java
./main/java/org/jboss/resteasy/jose/i18n/Messages.java
./main/java/org/jboss/resteasy/jose/jwe
./main/java/org/jboss/resteasy/jose/jwe/Algorithm.java
./main/java/org/jboss/resteasy/jose/jwe/CompressionAlgorithm.java
./main/java/org/jboss/resteasy/jose/jwe/crypto
./main/java/org/jboss/resteasy/jose/jwe/crypto/AES.java
./main/java/org/jboss/resteasy/jose/jwe/crypto/AESCBC.java
./main/java/org/jboss/resteasy/jose/jwe/crypto/AESGCM.java
./main/java/org/jboss/resteasy/jose/jwe/crypto/AuthenticatedCipherText.java
./main/java/org/jboss/resteasy/jose/jwe/crypto/CompositeKey.java
./main/java/org/jboss/resteasy/jose/jwe/crypto/DeflateHelper.java
./main/java/org/jboss/resteasy/jose/jwe/crypto/DeflateUtils.java
./main/java/org/jboss/resteasy/jose/jwe/crypto/DirectDecrypter.java
./main/java/org/jboss/resteasy/jose/jwe/crypto/DirectEncrypter.java
./main/java/org/jboss/resteasy/jose/jwe/crypto/HMAC.java
./main/java/org/jboss/resteasy/jose/jwe/crypto/JWECryptoParts.java
./main/java/org/jboss/resteasy/jose/jwe/crypto/RSA1_5.java
./main/java/org/jboss/resteasy/jose/jwe/crypto/RSA_OAEP.java
./main/java/org/jboss/resteasy/jose/jwe/crypto/RSADecrypter.java
./main/java/org/jboss/resteasy/jose/jwe/crypto/RSAEncrypter.java
./main/java/org/jboss/resteasy/jose/jwe/EncryptionMethod.java
./main/java/org/jboss/resteasy/jose/jwe/JWEBuilder.java
./main/java/org/jboss/resteasy/jose/jwe/JWEHeader.java
./main/java/org/jboss/resteasy/jose/jwe/JWEInput.java
./main/java/org/jboss/resteasy/jose/jws
./main/java/org/jboss/resteasy/jose/jws/Algorithm.java
./main/java/org/jboss/resteasy/jose/jws/crypto
./main/java/org/jboss/resteasy/jose/jws/crypto/HMACProvider.java
./main/java/org/jboss/resteasy/jose/jws/crypto/RSAProvider.java
./main/java/org/jboss/resteasy/jose/jws/JWSBuilder.java
./main/java/org/jboss/resteasy/jose/jws/JWSHeader.java
./main/java/org/jboss/resteasy/jose/jws/JWSInput.java
./main/java/org/jboss/resteasy/jwt
./main/java/org/jboss/resteasy/jwt/JsonSerialization.java
./main/java/org/jboss/resteasy/jwt/JsonWebToken.java
./main/java/org/jboss/resteasy/jwt/JWTContextResolver.java
```

Generally speaking, the classes in Keycloak is a subset of the classes in RESTEasy `jose-jwt`. In addition, Wildfly uses the `resteasy-crypto` and `jose-jws` modules by default. Here are the default modules in `wildfly-10.1.0.Final`:

```
system/layers/base/org/jboss/resteasy/jose-jwt/main/jose-jwt-3.0.19.Final.jar
system/layers/base/org/jboss/resteasy/jose-jwt/main/module.xml
```

Now let's check the `resteasy-crypto` module.

### resteasy-crypto

`resteasy-crypto` provides a basic toolset for common encryption work. For example, it contains classes like `DKIMSignature` for dealing with DKIM headers[^6], and it contains `KeyTools`, `PemUtils` and `DerUtils` for processing JSSE[^7] classes like `PrivateKey`, `PublicKey`, and `X509Certificate`. Same like `jose-jwt`, `resteasy-crypto` is shipped by default by Wildfly:

```
system/layers/base/org/jboss/resteasy/resteasy-crypto/main/module.xml
system/layers/base/org/jboss/resteasy/resteasy-crypto/main/resteasy-crypto-3.0.19.Final.jar
```

`Keycloak` has simliar classes, some are same, but they are not equal:

```
$ ls -1 ./common/src/main/java/org/keycloak/common/util | grep -i util
CRLUtils.java
CertificateUtils.java
CollectionUtil.java
DerUtils.java
EnvUtil.java
HostUtils.java
HtmlUtils.java
KerberosSerializationUtils.java
KeyUtils.java
KeystoreUtil.java
MimeTypeUtil.java
NetworkUtils.java
OCSPUtils.java
ObjectUtil.java
PemUtils.java
StreamUtil.java
UriUtils.java
```

In the future maybe we should try to maintain the shared part of classes between Keycloak and RESTEasy.

### resteasy-oauth

`resteasy-oauth` is a restful adapter to support OAuth protocol. I haven't checked the detail implementation in Keycloak side, but I guess this module is no longer needed and can be replaced by the feature provided by Keycloak. I need a more fine-grained study on Keycloak side to give my conclusion.

### skeleton-key-idm

I believe this project is now fully replaced by Keycloak and can be deprecated. Here are two articles you may want to read that describes the design and architecture of the `skeleton-key-idm`[^8] [^9].

### keystone

`keystone` is  a `Skeleton Keystone IDM` that supports `Openstack's Keystone protocol`. IMHO, the development of this project should be moved to Keycloak side, and RESTEasy should deprecate this module.

### login-module-authenticator

This module is just a simple one that contains two classes:

```
login-module-authenticator weli$ tree src/
src/
└── main
    └── java
        └── org
            └── jboss
                └── security
                    └── web
                        ├── DomainDelegatingAuthenticator.java
                        └── ThreadContext.java

6 directories, 2 files
```

I haven't done full analysis on the usage of this project. Maybe it's used by JBoss Web? I don't know yet. But I believe this sub-module could be removed in future.

### Conclusion

Here are my conclusions on RESTEasy security modules, it may not be accurate, and it's just based on my study till now. You can't use this as the final decision of RESTEasy community for the future. Here are the points:

- We should keep `jose-jwt` and `resteasy-crypto` modules because they are used by Wildfly.
- Maybe we can coordinate with Keycloak team to merge the shared part of codes. IMHO Keycloak can use `jose-jwt` and `resteasy-crypto` and don't maintain it in Keycloak, or vice versa.
- `resteasy-oauth`, `skeleton-key-idm` should be deprecated and users should use Keycloak instead.
- The development of `keystone` support should be moved to Keycloak side.
- Who is using `login-module-authenticator`? I guess it should be removed from RESTEasy. We need to know what project is using it.

Above are just some personal comments and they are not the decisions from RESTEasy community.

### _References_

---

[^1]: [Central Authentication Service (CAS).](https://github.com/apereo/cas)
[^2]: [OpenID.](https://en.wikipedia.org/wiki/OpenID)
[^3]: [Security Assertion Markup Language.](https://en.wikipedia.org/wiki/Security_Assertion_Markup_Language)
[^4]: [Identity provider.](https://en.wikipedia.org/wiki/Identity_provider)
[^5]: [Javascript Object Signing and Encryption (JOSE).](http://jose.readthedocs.io/en/latest/)
[^6]: [DomainKeys Identified Mail (DKIM).](http://www.dkim.org/)
[^7]: [Java Secure Socket Extension.](https://en.wikipedia.org/wiki/Java_Secure_Socket_Extension)
[^8]: [Scoping out Resteasy Skeleton Key Security.](https://bill.burkecentral.com/2012/11/21/scoping-out-resteasy-skeleton-key-security/)
[^9]: [Resteasy Skeleton Key Web SSO/OAuth.](https://developer.jboss.org/wiki/ResteasySkeletonKeyWebSSOOAuth)
