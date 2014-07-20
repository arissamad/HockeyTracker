import java.util.*;

public class Blob {

	protected int label;
	protected Polygon outerContour;
	protected List<Polygon> innerContours;
	
	private double area = -1;
	private double perimeter = -1;;
	private double circularity = -1;
	private BPoint centerOfGravity = null;
	
	public Blob(Polygon outerContour, byte label) {
		this.outerContour = outerContour;
		this.label = label;
		innerContours = new ArrayList<Polygon>();
	}
	
	public void addInnerContour(Polygon contour) {
		innerContours.add(contour);
	}
	
	public double getArea(){
		if(area != -1) {
			return area;
		}
		
		Polygon polyPoints = outerContour;
		
		int i, j, n = polyPoints.size();
		area = 0;

		for (i = 0; i < n; i++) {
			j = (i + 1) % n;
			area += polyPoints.getX(i) * polyPoints.getY(j);
			area -= polyPoints.getX(j) * polyPoints.getY(i);
		}
		area /= 2.0;
		area = Math.abs(area);
		return area;
	}
	
	public double getCircularity() {
		if(circularity != -1){
			return circularity;
		}
		
		double perimeter = getPerimeter();
		double size = getArea();
		
		circularity = (perimeter*perimeter) / size;
		return circularity;
	}
	
	public double getPerimeter() {
		
		if(perimeter != -1){
			return perimeter;
		}
		
		Polygon contour = outerContour;
	
		double peri = 0;
		if(contour.size() == 1)
		{
			peri=1;
			return peri;
		}
		int[] cc = contourToChainCode(contour);
		int sum_gerade= 0;
		for(int i = 0; i < cc.length;i++){
			if(cc[i]%2 == 0){
				sum_gerade++;
			}
		}
		peri = sum_gerade*0.948 + (cc.length-sum_gerade)*1.340;
		return peri;
	}
	
	private int[] contourToChainCode(Polygon contour) {
		int[] chaincode = new int[contour.size()-1];
		for(int i = 1; i <contour.size(); i++){
			int dx = contour.getX(i) - contour.getX(i-1);
			int dy = contour.getY(i) - contour.getY(i-1);
			
			if(dx==1 && dy==0){
				chaincode[i-1] = 0;
			}
			else if(dx==1 && dy==1){
				chaincode[i-1] = 7;
			}
			else if(dx==0 && dy==1){
				chaincode[i-1] = 6;
			}
			else if(dx==-1 && dy==1){
				chaincode[i-1] = 5;
			}
			else if(dx==-1 && dy==0){
				chaincode[i-1] = 4;
			}
			else if(dx==-1 && dy==-1){
				chaincode[i-1] = 3;
			}
			else if(dx==0 && dy==-1){
				chaincode[i-1] = 2;
			}
			else if(dx==1 && dy==-1){
				chaincode[i-1] = 1;
			}
		}
		
		return chaincode;
	}
	
	public BPoint getCenterOfGravity() {
		
		if(centerOfGravity != null){
			return centerOfGravity;
		}
		
	    int[] x = outerContour.getXPoints();
	    int[] y = outerContour.getYPoints();
	    int sumx = 0;
	    int sumy = 0;
	    double A = 0;

	    for(int i = 0; i < outerContour.size()-1; i++){
	    	int cross = (x[i]*y[i+1]-x[i+1]*y[i]);
	    	sumx = sumx + (x[i]+x[i+1])*cross;
	    	sumy = sumy + (y[i]+y[i+1])*cross;
	    	A = A + x[i]*y[i+1]-x[i+1]*y[i];
	    }
	    
	    A = 0.5*A;
	    
	    centerOfGravity = new BPoint((int) (sumx/(6*A)),(int) (sumy/(6*A)));
	    
		if(getArea() == 1) {
			centerOfGravity = new BPoint(x[0],y[0]);
		}

		return centerOfGravity;
	}
}
