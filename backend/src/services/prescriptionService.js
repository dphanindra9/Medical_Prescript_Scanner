const { GoogleGenerativeAI } = require('@google/generative-ai');
const fs = require('fs');
const path = require('path');

async function processPrescriptionImage(imagePath) {
  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey || apiKey === 'your_api_key_here') {
      throw new Error('Missing or invalid GEMINI_API_KEY in .env file');
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

    // Read the image file
    // Determine mimeType based on extension (multer enforces .jpg fallback for us)
    const ext = path.extname(imagePath).toLowerCase();
    let mimeType = "image/jpeg";
    if (ext === '.png') mimeType = "image/png";
    else if (ext === '.webp') mimeType = "image/webp";

    const imageParts = [
      {
        inlineData: {
          data: Buffer.from(fs.readFileSync(imagePath)).toString("base64"),
          mimeType: mimeType
        }
      }
    ];

    const prompt = `
      You are a specialized medical AI designed to extract structured data from medical prescriptions.
      Extract the following information from the prescription image:
      - doctorName (string)
      - patientName (string)
      - date (string, preferably in YYYY-MM-DD format)
      - instructions (string, general advice or notes)
      - medicines (array of objects, each containing):
        - name (string)
        - dosage (string, e.g. "500mg" or "Unknown")
        - frequency (string, e.g. "1-0-1" or "Twice a day")
        - duration (string, e.g. "5 days" or "Unknown")
      
      Respond STRICTLY with a valid JSON object containing exactly these fields. Do not include markdown code blocks like \`\`\`json or any other text. Return raw JSON.
    `;

    const result = await model.generateContent([prompt, ...imageParts]);
    const responseText = result.response.text();
    
    // Clean up response if the model included markdown tags
    const cleanedText = responseText.replace(/```json/gi, '').replace(/```/gi, '').trim();
    const parsedData = JSON.parse(cleanedText);

    return {
      doctorName: parsedData.doctorName || 'Unknown Doctor',
      patientName: parsedData.patientName || 'Unknown Patient',
      date: parsedData.date || new Date().toISOString().split('T')[0],
      instructions: parsedData.instructions || '',
      medicines: Array.isArray(parsedData.medicines) ? parsedData.medicines : [],
      rawText: "Extracted via Gemini Vision AI"
    };

  } catch (error) {
    console.error('Error processing image with Gemini:', error);
    throw new Error('Failed to extract data using AI: ' + error.message);
  }
}

module.exports = { processPrescriptionImage };
