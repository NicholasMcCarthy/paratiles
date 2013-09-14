
import weka.core.Attribute;
import java.util.ArrayList;
import java.util.List;

public class Test {

   public static void main(String[] args) {

      List my_values = new ArrayList(1);
      my_values.add("test");

      Attribute att=  new Attribute("Test", my_values);


   }
}

