import org.apache.ws.security.components.crypto.Crypto;
import org.apache.ws.security.components.crypto.CryptoFactory;
import org.apache.ws.security.WSSConfig;
import org.apache.ws.security.WSPasswordCallback;
import org.apache.ws.security.WSSecurityEngine;
import org.apache.ws.security.WSSecurityEngineResult;
import org.apache.ws.security.util.XMLUtils;
import org.w3c.dom.Document;

import javax.security.auth.callback.Callback;
import javax.security.auth.callback.CallbackHandler;
import javax.security.auth.callback.UnsupportedCallbackException;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.charset.Charset;
import java.nio.file.Paths;
import java.util.Properties;

// API docs at https://ws.apache.org/wss4j/apidocs/
public class DecryptMessage
{
  public static void main(String[] args)
  {
    if (args.length < 3) {
      printUsage();
      System.exit(1);
    }

    String inFileName = args[0];
    String keyFileName = args[1];
    String keyFilePass = args[2];
    boolean ignoreTimestamp = Boolean.getBoolean("decrypt_ignore_wsse_timestamp");

    try
    {
      String encrypted_xml = new String(
        Files.readAllBytes(Paths.get(inFileName)), Charset.defaultCharset()
      );
      String document = decrypt(
        encrypted_xml, keyFileName, keyFilePass, ignoreTimestamp
      );
      System.out.println(document);
    }
    catch (Exception e)
    {
      e.printStackTrace();
      System.exit(255);
    }
  }

  public static Document getSOAPDoc(String document) throws Exception
  {
    InputStream in = new ByteArrayInputStream(document.getBytes());
    DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
    factory.setNamespaceAware(true);
    DocumentBuilder builder = factory.newDocumentBuilder();
    Document doc = builder.parse(in);
    return doc;
  }

  private static Properties loadCryptoProperties(String keyfile) throws IOException {
    Properties properties = new Properties();
    InputStream propertiesStream = DecryptMessage.class.getResourceAsStream(VBMS_PROPERTIES);
    if (propertiesStream == null) {
      throw new RuntimeException("Unable to load " + VBMS_PROPERTIES + ". Is it in your classpath?");
    }
    properties.load(propertiesStream);
    properties.setProperty("org.apache.ws.security.crypto.merlin.keystore.file", keyfile);
    return properties;
  }

  public static Crypto getCrypto(String keyfile) throws Exception {
    Properties properties = loadCryptoProperties(keyfile);
    return CryptoFactory.getInstance(properties);
  }

  public static String decrypt(String encryptedXml, String keyfile,
                               String keypass, boolean ignoreTimestamp) throws Exception {
    Crypto signCrypto = getCrypto(keyfile);
    Crypto deCrypto = getCrypto(keyfile);
    CallbackHandler handler = new WSSCallbackHandler(keypass);
    WSSecurityEngine secEngine = new WSSecurityEngine();
    if (ignoreTimestamp) {
      WSSConfig config = WSSConfig.getNewInstance();
      config.setTimeStampStrict(false);
      config.setTimeStampFutureTTL(Integer.MAX_VALUE);
      config.setTimeStampTTL(Integer.MAX_VALUE);
      secEngine.setWssConfig(config);
    }

    Document doc = getSOAPDoc(encryptedXml);
    java.util.List<WSSecurityEngineResult> results = secEngine.processSecurityHeader(doc, null, handler, signCrypto, deCrypto);
    return XMLUtils.PrettyDocumentToString(doc);
  }

  public static class WSSCallbackHandler implements CallbackHandler {
    public String keypass;

    public WSSCallbackHandler(String keypass) {
      this.keypass = keypass;
    }

    public void handle(Callback[] callbacks) throws IOException, UnsupportedCallbackException {
      for (Callback callback : callbacks) {
        if (callback instanceof WSPasswordCallback) {
          WSPasswordCallback cb = (WSPasswordCallback) callback;
          cb.setPassword(this.keypass);
        }
      }
    }
  }

  private static void printUsage() {
    System.err.println("java DecryptMessage INFILE KEYFILE KEYPASS");
  }

  // Properties file with default crypto configuration for the test environment.
  private static final String VBMS_PROPERTIES = "vbms.properties";
}
