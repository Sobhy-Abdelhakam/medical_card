# Map Feature Debugging Guide

## Issues Identified and Solutions

### 1. **Missing Google Maps API Key** (CRITICAL)

**Problem**: The most critical issue is that the Google Maps API key is not configured.

**Solution**:
1. Get a Google Maps API key from the [Google Cloud Console](https://console.cloud.google.com/)
2. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API (if needed)
3. Add your API key to `android/local.properties`:
   ```
   MAPS_API_KEY=YOUR_ACTUAL_API_KEY_HERE
   ```

### 2. **API Endpoint Issues**

**Problem**: The app tries to fetch data from `https://providers.euro-assist.com/api/arabic-providers` which might not be accessible.

**Solutions**:
1. **Test Mode**: Use the built-in test mode by tapping the orange science icon (🔬) in the floating action buttons
2. **Check API**: Verify the API endpoint is working by testing it in a browser or Postman
3. **Network Permissions**: Ensure internet permissions are properly configured

### 3. **Location Permissions**

**Problem**: Runtime location permissions might not be granted.

**Solution**:
- The app will automatically request location permissions
- If denied, users can manually enable them in device settings
- Check that location services are enabled on the device

### 4. **Map Rendering Issues**

**Problem**: Map might load but not display markers due to data issues.

**Solution**:
- Use test mode to verify map functionality with sample data
- Check debug console for error messages
- Verify coordinate validation

## Step-by-Step Debugging Instructions

### Step 1: Configure Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the required APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
4. Create credentials (API Key)
5. Edit `android/local.properties` and add:
   ```
   MAPS_API_KEY=YOUR_ACTUAL_API_KEY_HERE
   ```

### Step 2: Test with Sample Data

1. Run the app
2. Navigate to the map screen
3. Tap the orange science icon (🔬) to enable test mode
4. The map should now show 3 sample markers around Cairo
5. If markers appear, the map functionality is working

### Step 3: Test API Connection

1. Disable test mode (tap the green check icon)
2. Check the debug console for API response messages
3. If API fails, the app will show an error message
4. Verify the API endpoint is accessible

### Step 4: Test Location Services

1. Ensure location services are enabled on your device
2. Grant location permissions when prompted
3. The map should center on your current location
4. A blue marker should appear at your location

### Step 5: Debug Information

The app includes debug logging. Check the console for messages like:
- "Using test mode with X sample markers"
- "Fetched X markers from API"
- "Created X valid markers"
- "Location loaded: lat, lng"

## Common Error Messages and Solutions

### "لا يوجد اتصال بالإنترنت"
- Check internet connection
- Verify API endpoint is accessible
- Try test mode to isolate the issue

### "تعذر تحديد الموقع"
- Enable location services
- Grant location permissions
- Check device GPS settings

### "حدث خطأ أثناء تحميل البيانات"
- API endpoint might be down
- Check API response in debug console
- Use test mode to verify map functionality

### Empty Map Grid
- Most likely missing Google Maps API key
- Check `android/local.properties` configuration
- Verify API key is valid and has correct permissions

## Testing Checklist

- [ ] Google Maps API key configured
- [ ] Test mode shows sample markers
- [ ] Location services working
- [ ] API endpoint accessible
- [ ] Markers display correctly
- [ ] Marker tap functionality works
- [ ] Map controls (zoom, pan) work
- [ ] Legend displays correctly

## Additional Notes

- The app includes fallback mechanisms for icon generation
- Coordinate validation prevents invalid markers
- Timeout handling for API requests
- Offline detection and retry functionality
- Comprehensive error handling and user feedback

## Support

If issues persist after following this guide:
1. Check the debug console for specific error messages
2. Verify all configuration steps are completed
3. Test on different devices/emulators
4. Ensure all dependencies are properly installed


