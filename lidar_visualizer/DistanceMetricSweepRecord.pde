import org.christopherfrantz.dbscan.DistanceMetric;

/**
 * Distance metric implementation for numeric values.
 * 
 * @author <a href="mailto:cf@christopherfrantz.org>Christopher Frantz</a>
 *
 */
public class DistanceMetricSweepRecord implements DistanceMetric<SweepRecord>{

  @Override
  public double calculateDistance(SweepRecord rec1, SweepRecord rec2) {
    float x1 = (width / 2) + cos(radians(rec1.angle)) * rec1.distance;
    float y1 = (height / 2) + sin(radians(rec1.angle)) * rec1.distance;
    
    float x2 = (width / 2) + cos(radians(rec2.angle)) * rec2.distance;
    float y2 = (height / 2) + sin(radians(rec2.angle)) * rec2.distance;
    
    return Math.sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
  }
}