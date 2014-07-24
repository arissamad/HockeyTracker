
import java.util.*;

public class BlobLabeler {
	
	protected int width;
	protected int height;
	protected int arrayLength;
	
	public static byte objectColor = -1;
	public static byte backgroundColor = 0;
	protected byte noLabelValue = 0;
	
	protected byte labelCount = 100;
	
	byte[] binaryData;
	byte[] labelImage;
	
	List<Blob> allBlobs;
	Map<Byte, Blob> blobLookup;
	
	public BlobLabeler() {
		allBlobs = new ArrayList();
		blobLookup = new HashMap();
	}
	
	/**
	 * Each byte in binaryData is either 0 or 1.
	 */
	public void processImage(byte[] binaryData, int width, int height) {
		this.binaryData = binaryData;
		this.width = width;
		this.height = height;
		
		arrayLength = width * height;
		labelImage = new byte[arrayLength];
		
        // Prevent edge errors by filling 1-pixel background border all around
        
		// First, make the first row completely background. This way I don't have to add offset.
		for(int x=0; x<width; x++) {
			binaryData[x] = backgroundColor;
		}
        
        // Also make the last row completely background. Makes the algorithm more robust.
        int beginIndex = (this.height-1) * width;
        for(int x=0; x<width; x++) {
            binaryData[beginIndex + x] = backgroundColor;
        }
        
        // Sides
        for(int y=0; y<height; y++) {
            binaryData[index(0,y)] = backgroundColor;
            binaryData[index(width-1, y)] = backgroundColor;
        }
		
		for(int y=0; y<height-1; y++) {
			for(int x=0; x<width; x++) {
				
				byte value = binaryData[index(x,y)];
				
				try {
					
					if(value == objectColor) {
						if (isNewExternalContour(x, y) && hasNoLabel(x, y)) {
							labelImage[index(x,y)] = labelCount;
							Polygon outerContour = traceContour(x, y, labelCount, (byte) 1);
						
							Blob blob = new Blob(outerContour, labelCount);
							allBlobs.add(blob);
							blobLookup.put(labelCount, blob);
							
							++labelCount;
						}
						
						try {
							isNewInternalContour(x,y);
						} catch(Exception e) {
							System.out.println("Problem with isNewInternalContour.");
							isNewInternalContour(x,y);
						}
						
						if (isNewInternalContour(x, y)) {
							byte label = labelImage[index(x,y)];
							if (hasNoLabel(x, y)) {
								label = labelImage[index(x-1, y)];
								labelImage[index(x,y)] = label;
							}
							
							try{
								Polygon innerContour = traceContour(x, y, label, (byte) 2);
								
								Blob blob = blobLookup.get(label);
								blob.addInnerContour(innerContour);
								
							} catch(Exception e){
							  System.out.println("Got exception: " + e.getMessage());
							  traceContour(x, y, label, (byte) 2);
							}
						} else if (hasNoLabel(x, y)) {
						
							byte precedingLabel = labelImage[index(x-1, y)];
							labelImage[index(x,y)] = precedingLabel;
						}
					}
				} catch(Exception e) {
					System.out.println("Exception at (" + x + ", " + y + ")");
				}
			}
		}
	}
	
	protected int index(int x, int y) {
		int index = (y * width) + x;
		if(index > arrayLength-1) index = arrayLength-1;
		return index;
	}
	
	private boolean hasNoLabel(int x, int y) {
		byte label = labelImage[index(x,y)];
		return label == noLabelValue;
	}
	
	private boolean isNewExternalContour(int x, int y) {
		return isBackground(x, y - 1);
	}

	private boolean isNewInternalContour(int x, int y) {
		return isBackground(x, y + 1) && !isMarked(x, y + 1);
	}
	
	private boolean isMarked(int x, int y) {
		return labelImage[index(x, y)] == -1;
	}

	private boolean isBackground(int x, int y) {
		return this.binaryData[index(x,y)] == backgroundColor;
	}
	
	private Polygon traceContour(int x, int y, byte label, byte start) {

		Polygon contour = new Polygon();
		BPoint startPoint = new BPoint(x, y);
		contour.addPoint(x, y);

		BPoint nextPoint = nextPointOnContour(startPoint, start);
		
		if (nextPoint.x == -1) {
			// Point is isolated;
			return contour;
		}
		BPoint T =  new BPoint(nextPoint.x,nextPoint.y);
		boolean equalsStartpoint = false;
		do {
			contour.addPoint(nextPoint.x, nextPoint.y);
			labelImage[index(nextPoint.x, nextPoint.y)] = label;
			equalsStartpoint = nextPoint.equals(startPoint);
			nextPoint = nextPointOnContour(nextPoint, -1);
            
            if(nextPoint.getY() > height) {
                System.out.println("Next point has exceeded height: " + nextPoint.getY());
                return contour;
            }
            if(nextPoint.getX() > width) {
                System.out.println("Next point has exceeded width: " + nextPoint.getX());
                return contour;
            }
		} while (!equalsStartpoint || !nextPoint.equals(T));

		return contour;
	}
	
	int iterationorder[] = { 5, 4, 3, 6, 2, 7, 0, 1 };
	BPoint prevContourPoint;

	// start = 1 -> External Contour
	// start = 2 -> Internal Contour
	private final BPoint nextPointOnContour(BPoint startPoint, int start) {

		/*
		 ************
		 *5 * 6 * 7 * 
		 *4 * p * 0 * 
		 *3 * 2 * 1 * 
		 ************
		 */
		BPoint[] helpindexToPoint = new BPoint[8];

		byte[] neighbors = new byte[8]; // neighbors of p
		int x = startPoint.x;
		int y = startPoint.y;

		int I = 2;
		int k = I - 1;
		
		int u = 0;
		for (int i = 0; i < 3; i++) {
			for (int j = 0; j < 3; j++) {
				int window_x = (x - k + i);
				int window_y = (y - k + j);
				if (window_x != x || window_y != y) {
					neighbors[iterationorder[u]] = binaryData[index(window_x, window_y)];
					helpindexToPoint[iterationorder[u]] = new BPoint(window_x,
							window_y);
					u++;
				}
			}
		}
		ArrayList<BPoint> indexToPoint = new ArrayList<BPoint>(
				Arrays.asList(helpindexToPoint));

		int NOSTARTPOINT = -1;
		int STARTEXTERNALCONTOUR = 1;
		int STARTINTERNALCONTOUR = 2;

		if(start == NOSTARTPOINT) {
			int prevContourPointIndex = indexToPoint.indexOf(prevContourPoint);
			start = (prevContourPointIndex + 2) % 8;
		} else if(start == STARTEXTERNALCONTOUR) {
			start = 7;
		} else if(start == STARTINTERNALCONTOUR) {
			start = 3;
		}
		
		int counter = start;
		int pos = -2;

		BPoint returnPoint = null;
		while (pos != start) {
			pos = counter % 8;
			if (neighbors[pos] == objectColor) {
				prevContourPoint = startPoint;
				returnPoint = indexToPoint.get(pos);
				return returnPoint;
			}
			BPoint p = indexToPoint.get(pos);
			if (neighbors[pos] == backgroundColor) {
				try {
					labelImage[index(p.x, p.y)] = -1;
				} catch (Exception e) {
					System.out.println("GOT AN EXCEPTION");
				}
			}

			counter++;
			pos = counter % 8;
		}
		
		BPoint isIsolated = new BPoint(-1, -1);
		return isIsolated;
	}
	
	public void filterBlobs() {
		Iterator<Blob> it = allBlobs.iterator();
		
		while(it.hasNext()) {
			Blob blob = it.next();
			if(blob.getArea() < 50) it.remove();
		}
	}
	
	public Blob findMostLikelyBlob() {
		if(allBlobs.size() == 0) return null;
		
		SortedMap<Double, Blob> sortedMap = new TreeMap();
		
		for(Blob blob: allBlobs) {
			double score = 0; // The smaller score wins.
			double circularity = blob.getCircularity();
            
            if(circularity > 200) continue; // Just too not circular.
			
			// The bigger the circularity, the less circular, and the less likely it's our blob.
			// 10 means really circular.
			//double circularityScore = circularity / 500;
			//if(circularityScore > 1) circularity = 1;
			
			//score += circularityScore;
            score = 1/blob.getArea();
			
			sortedMap.put(score, blob);
		}
		
		Blob winnerBlob = sortedMap.values().iterator().next();
		
		BPoint cg = winnerBlob.getCenterOfGravity();
        
        mark(winnerBlob.getCenterOfGravity());
		
		return winnerBlob;
	}

	public void printDebuggingInfo() {
		System.out.println("Number of blobs found: " + allBlobs.size());
		
		for(int i=0; i<allBlobs.size(); i++) {
			Blob blob = allBlobs.get(i);
			System.out.println("Blob " + i + ": ");
			System.out.println("  CG: " + blob.getCenterOfGravity());
			System.out.println("  Area: " + blob.getArea());
			System.out.println("  Perimeter: " + blob.getPerimeter());
			System.out.println("  Circularity: " + blob.getCircularity());
			
			mark(blob.getCenterOfGravity());
		}
	}
	
	protected void mark(BPoint point) {
		int max = width * height;
		max--;
		
		byte currColor = backgroundColor;
        
		for(int i=-15; i<15; i++) {
			
			if(i%2 == 0) currColor = backgroundColor;
			else currColor = -1;
			
			int x = point.getX() + i;
			if(x < 0) x = 0;
			if(x > max) x = max;
			
			binaryData[index(x, point.getY())] = currColor;
			
			int y = point.getY() + i;
			if(y < 0) y = 0;
			if(y > max) y = max;
			binaryData[index(point.getX(), y)] = currColor;
            
		}
        
	}
}
