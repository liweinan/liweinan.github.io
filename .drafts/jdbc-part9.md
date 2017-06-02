We can verify the above analysis by using a sample project. I have put the sample project here:

```url
https://github.com/liweinan/code.weinan.github.io/tree/master/jdbc-in-wildfly
```

The project contains one main class `DataSourceFetcher`, and here is the code:

```java
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Response;

/**
 * Created by weli on 03/05/2017.
 */
@Path("/")
public class DataSourceFetcher implements DataSourceFetcherInterface {


    public String hello() {
        try {
            InitialContext ctx = new InitialContext();
            Object obj = ctx.lookup("java:jboss/datasources/weli");
            return obj.getClass().toString();

        } catch (NamingException e) {
            e.printStackTrace();
        }
        return null;
    }

}
```

The above code is a restful webservice, and it will fetch the data source via the JNDI context.