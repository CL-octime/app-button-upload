// FileList.js
import React, { useState } from 'react';
import DownloadButton from './DownloadButton';
import styles from './FileList.module.css'; // 

const files = [
  'Planning.pdf',
  'Anomalies.pdf',
  'Données de base OCTIME.pdf',
  'LES MODULES.pdf',
  'Les paramètres.pdf',
  'Les utilitaires.pdf',
  'Manager v10.pdf',
  'Optimisation.pdf',
  'Employé v10.pdf'
  // ... ajoutez tous les noms de fichiers ici
];

// FileList.js
// ... autres imports ...
const FileList = () => {
  const [selectedFile, setSelectedFile] = useState('');

  return (
    <div className={styles.fileListContainer}>
      <select
        value={selectedFile}
        onChange={(e) => setSelectedFile(e.target.value)}
        className={styles.fileSelector}
      >
        <option value="">Sélectionnez un fichier</option>
        {files.map((file, index) => (
          <option key={index} value={file}>
            {file}
          </option>
        ))}
      </select>
      <DownloadButton fileName={selectedFile} /> {/* Retirer la condition pour le test */}
    </div>
  );
};
export default FileList; 