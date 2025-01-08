import JSZip from 'jszip';

export async function downloadAndUnzipFile(url: string): Promise<File[]> {
  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Failed to download file: ${response.statusText}`);
    }
    
    const blob = await response.blob();
    const zip = new JSZip();
    const contents = await zip.loadAsync(blob);
    const files: File[] = [];
    
    for (const [path, file] of Object.entries(contents.files)) {
      if (!file.dir) {
        try {
          const content = await file.async('blob');
          // Remove project/ prefix and normalize path
          const normalizedPath = path.replace(/^[^/]+\//, '').replace(/^\/+/, '');
          
          // Skip sensitive files and .bolt directory
          if (content.size > 0 && 
              !normalizedPath.includes('.bolt/') &&
              !normalizedPath.includes('.env')) {
            files.push(new File([content], normalizedPath));
          }
        } catch (error) {
          console.error(`Error processing file ${path}:`, error);
        }
      }
    }
    
    // Add .env.example template
    const envExample = new File([
      'VITE_SUPABASE_URL=your_supabase_url\n' +
      'VITE_SUPABASE_ANON_KEY=your_supabase_anon_key\n' +
      'VITE_STRIPE_PUBLIC_KEY=your_stripe_public_key\n'
    ], '.env.example');
    files.push(envExample);
    
    if (files.length === 0) {
      throw new Error('No valid files found in ZIP');
    }
    
    return files;
  } catch (error: any) {
    throw new Error(`Failed to process ZIP file: ${error.message}`);
  }
}