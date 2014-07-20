
public class BPoint {
	protected int x;
	protected int y;
	
	public BPoint(int x, int y) {
		this.x = x;
		this.y = y;
	}

	public int getX() {
		return x;
	}

	public void setX(int x) {
		this.x = x;
	}

	public int getY() {
		return y;
	}

	public void setY(int y) {
		this.y = y;
	}
	
	@Override
	public boolean equals(Object other) {
		BPoint otherPoint = (BPoint) other;
		if(x != otherPoint.x) return false;
		if(y != otherPoint.y) return false;
		
		return true;
	}
	
	public String toString() {
		return "(" + x + ", " + y + ")";
	}
}
