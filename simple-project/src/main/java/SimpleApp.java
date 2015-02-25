import org.apache.spark.api.java.*;
import org.apache.spark.SparkConf;
import org.apache.spark.api.java.function.Function;
import java.util.List;
import java.util.Iterator;

public class SimpleApp {
	public static void main(String[] args) {
		String logFile = "README.md"; // Should be some file on your system
		SparkConf conf = new SparkConf().setAppName("Simple Application");
		JavaSparkContext sc = new JavaSparkContext(conf);
		JavaRDD<String> logData = sc.textFile(logFile).cache();
		//List<String> test = logData.collect();
		//Iterator<String> test2 = test.iterator();
		


		/*while (test2.hasNext()) {
			System.out.println(test2.next());
		}*/
		//save logData to a text file
		//logData.saveAsTextFile("/homes/sun224/test_readme.txt");		
		
		System.out.printf("Hello Ni Hao!\n %s\n", logData.count());
		
		
	}
}
