import styles from "./Example.module.css";

// interface Props {
//     text: string;
//     value: string;
//     onClick: (value: string) => void;
// }

// export const Example = ({ text, value, onClick }: Props) => {
//     return (
//         <div className={styles.example} onClick={() => onClick(value)}>
//             <p className={styles.exampleText}>{text}</p>
//         </div>
//     );
// };




interface Props {
    text: string;
    value: string;
    onClick: (value: string) => void;
    onNewButtonClick?: () => void; // Nouveau prop pour le bouton supplémentaire
}

export const Example = ({ text, value, onClick, onNewButtonClick }: Props) => {
    return (
        <div className={styles.example}>
            <p className={styles.exampleText} onClick={() => onClick(value)}>{text}</p>
            {onNewButtonClick && (
                <button onClick={onNewButtonClick}>Nouveau Bouton</button>
            )}
        </div>
    );
};

