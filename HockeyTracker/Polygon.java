import java.util.*;


public class Polygon {
	
	protected List<Integer> xpoints;
	protected List<Integer> ypoints;
	
	public Polygon() {
		xpoints = new ArrayList();
		ypoints = new ArrayList();
	}
	
	public void addPoint(int x, int y) {
		xpoints.add(x);
		ypoints.add(y);
	}
	
	public int getX(int index) {
		return xpoints.get(index);
	}
	
	public int getY(int index) {
		return ypoints.get(index);
	}
	
	public int size() {
		return xpoints.size();
	}
	
	public int[] getXPoints() {
		int[] array = new int[xpoints.size()];
		for(int i = 0; i < xpoints.size(); i++) array[i] = xpoints.get(i);
		
		return array;
	}
	
	public int[] getYPoints() {
		int[] array = new int[ypoints.size()];
		for(int i = 0; i < ypoints.size(); i++) array[i] = ypoints.get(i);
		
		return array;
	}
}
