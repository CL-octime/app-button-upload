const express = require('express');
const multer = require('multer');
const app = express();
const path = require('path');

// Utilisation d'un chemin relatif pour le répertoire 'data_save'
const dataSavePath = path.join(__dirname, 'data_save');

// Vérifier si le répertoire existe, sinon le créer
const fs = require('fs');
if (!fs.existsSync(dataSavePath)){
    fs.mkdirSync(dataSavePath, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, dataSavePath); // Utilisation du chemin relatif
  },
  filename: (req, file, cb) => {
    cb(null, file.originalname); // Utiliser le nom de fichier original
  },
});

const upload = multer({ storage: storage });
app.post('/upload', upload.single('file'), (req, res) => {
  res.send('Fichier téléchargé avec succès');
});

// Si vous souhaitez que le serveur serve les fichiers statiques :
app.use('/data_save', express.static(dataSavePath));

const port = 3000; // Port sur lequel votre serveur va écouter
app.listen(port, () => {
  console.log(`Serveur démarré sur le port ${port}`);
});
