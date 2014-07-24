
/**
 * Java Analyzer (JA)
 */
public class JAProcessor {
    
	private float hue, saturation, brightness;
	private float hueMin, hueMax;
	private float saturationMin, saturationMax;
	private float brightnessMin, brightnessMax;
    
    protected int playerLocation; // From 0 (all the way left) to 100 (all the way right).
    
	protected byte[] binaryData;
    
	public JAProcessor() {
		System.out.println("JAProcessor initialized.");
		
		hueMin = 0.6f;
		hueMax = 0.7f;
		saturationMin = 0.8f;
		saturationMax = 1;
		brightnessMin = 0.5f;
		brightnessMax = 1;
	}

	public void processRawData(byte[] rawData, int width, int height) {
        
		int arrayLength = width * height;
		binaryData = new byte[arrayLength];
		
		// First, get binary image based on HSB banding
		int compountIndex = 0;
		int simpleIndex = 0;
		
		int inBandCount = 0;
		int outBandCount = 0;
		
		for(int y=0; y<height; y++) {
			for(int x=0; x<width; x++) {
				
				readHsb(rawData, compountIndex);
				
				if(inBand()) {
					binaryData[simpleIndex] = BlobLabeler.objectColor;
					//inBandCount++;
				} else {
					binaryData[simpleIndex] = BlobLabeler.backgroundColor;
					//outBandCount++;
				}
                
				compountIndex += 4;
				simpleIndex++;
			}
		}
		
		//System.out.println("In-band/Out-band pixels: " + inBandCount + "/" + outBandCount);
		//System.out.println("Now detecting blobs...");
        
		// Now, label the binary image
		BlobLabeler blobLabeler = new BlobLabeler();
		blobLabeler.processImage(binaryData, width, height);
        
        //System.out.println("Finished detecting blobs.");
        
		blobLabeler.filterBlobs();
		//blobLabeler.printDebuggingInfo();
		
		Blob blob = blobLabeler.findMostLikelyBlob();
		
		if(blob == null) {
			System.out.println("Candidate blob not found.");
            playerLocation = 0; // Give a zero position, which means slowly move to middle.
			return;
		}
		
		BPoint cg = blob.getCenterOfGravity();
		float xLocation = 100.0f * (float)cg.getX()/(float)width;
        playerLocation = (int) xLocation;
		System.out.println("Player x percentage: " + playerLocation);
	}
    
    public int getPlayerLocation() {
        return playerLocation;
    }
	
	public byte[] getBinaryData() {
		return binaryData;
	}
    
    public void stop() {
        playerLocation = 50;
    }
	
	protected void readHsb(byte[] rawData, int beginIndex) {
		byte rb = rawData[beginIndex];
		byte gb = rawData[beginIndex+1];
		byte bb = rawData[beginIndex+2];
		
		rgbtohsb(rb, gb, bb);
	}
                 
	protected void setBand(byte colorRed, byte colorGreen, byte colorBlue) {
		rgbtohsb(colorRed, colorGreen, colorBlue);
		
		System.out.println("Setting band for RGB: (" + 
				(colorRed&0xFF) + "," + (colorGreen&0xFF) + "," + (colorBlue&0xFF) + 
				") to HSB: (" + hue + ", " + saturation + ", " + brightness + ").");
		
		hueMin = hue - 0.05f;
		hueMax = hue + 0.05f;
		
		saturationMin = saturation - 0.2f;
		saturationMax = 1.0f;
		
		brightnessMin = brightness - 0.3f;
		brightnessMax = 1.0f;
	}
	
	public void rgbtohsb(byte redByte, byte greenByte, byte blueByte) {
		
		int r = redByte & 0xFF;
		int g = greenByte & 0xFF;
		int b = blueByte & 0xFF;
		
		int cmax = (r > g) ? r : g;
		if (b > cmax) cmax = b;
		int cmin = (r < g) ? r : g;
		if (b < cmin) cmin = b;

		brightness = ((float) cmax) / 255.0f;
		if (cmax != 0)
		    saturation = ((float) (cmax - cmin)) / ((float) cmax);
		else
		    saturation = 0;
		if (saturation == 0)
		    hue = 0;
		else {
		    float redc = ((float) (cmax - r)) / ((float) (cmax - cmin));
		    float greenc = ((float) (cmax - g)) / ((float) (cmax - cmin));
		    float bluec = ((float) (cmax - b)) / ((float) (cmax - cmin));
		    if (r == cmax)
		    hue = bluec - greenc;
		    else if (g == cmax)
		        hue = 2.0f + redc - bluec;
		        else
		    hue = 4.0f + greenc - redc;
		    hue = hue / 6.0f;
		    if (hue < 0)
		    hue = hue + 1.0f;
		}
	}
	
	public boolean inBand() {
		if(hue > hueMax || hue < hueMin) return false;
		if(saturation > saturationMax || saturation < saturationMin) return false;
		if(brightness > brightnessMax || brightness < brightnessMin) return false;
		
		return true;
	}
}
