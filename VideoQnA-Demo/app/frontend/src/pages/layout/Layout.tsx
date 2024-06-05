import { Outlet, Link } from "react-router-dom";

import styles from "./Layout.module.css";

const Layout = () => {
    return (
        <div className={styles.layout}>
            <header className={styles.header} role={"banner"}>
                <div className={styles.headerContainer}>
                    <Link to="/" className={styles.headerTitleContainer}>
                        <h3 className={styles.headerTitle}>AI-powered search | Demo</h3>
                    </Link>
                    <h4 className={styles.headerRightText}>Powered by Azure AI Video Indexer</h4>
                </div>
            </header>

            <Outlet />
            <footer className={styles.footer}>
                <div className={styles.footerText}>
                    To understand how our AI technology works, read Azure AI Video Indexer’s{" "}
                    <a target="_blank" href="https://learn.microsoft.com/en-us/legal/azure-video-indexer/transparency-note">
                        Transparency Note
                    </a>
                    . For more information,{" "}
                    <a target="_blank" href="https://learn.microsoft.com/en-us/azure/azure-video-indexer/">
                        learn about Azure AI Video Indexer
                    </a>{" "}
                    and read our{" "}
                    <a target="_blank" href="https://privacy.microsoft.com/en-US/privacystatement">
                        Privacy Statement
                    </a>
                    .
                </div>
            </footer>
        </div>
    );
};

export default Layout;
