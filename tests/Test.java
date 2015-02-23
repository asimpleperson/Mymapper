import org.apache.spark.*;
import org.apache.spark.api.java.function.*;
import org.apache.spark.streaming.*;
import org.apache.spark.streaming.api.java.*;
import org.apache.spark.api.java.*;

import scala.Tuple2;

public class Test {
	public static void main (String[] args) {
		SparkConf conf = new SparkConf().setMaster("local").setAppName("appName");
		JavaSparkContext jssc = new JavaSparkContext(conf);
		
		while (true) {
		
		}
		
	}
}
