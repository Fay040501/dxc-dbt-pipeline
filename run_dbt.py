"""
run_dbt.py — Wrapper DBT avec notification Gmail
DXC Project — Alassane Fofana Yahaya

Usage :
    python run_dbt.py

Configuration :
    Renseigner les variables dans la section CONFIG ci-dessous,
    ou mieux, les mettre dans un fichier .env (voir commentaires).

Planification Windows Task Scheduler :
    Programme : python
    Arguments  : run_dbt.py
    Dossier    : C:\\chemin\\vers\\dxc_project
"""

import subprocess
import smtplib
import logging
import os
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from datetime import datetime
from pathlib import Path

# ============================================================
# CONFIG — à adapter ou charger depuis .env
# ============================================================
GMAIL_USER     = "fofanaalassaneyahaya@gmail.com"          # ton adresse Gmail
GMAIL_PASSWORD = "mxij nzsq znrz idtc"          # mot de passe d'application Google
DESTINATAIRE   = "fofanaalassaneyahaya@gmail.com"          # qui reçoit le mail

DBT_PROJECT_DIR = Path(__file__).parent          # dossier où se trouve ce script
DBT_COMMAND     = ["dbt", "run"]                 # ou ["dbt", "run", "--full-refresh"]
DBT_TEST        = ["dbt", "test"]                # tests après le run

LOG_DIR = DBT_PROJECT_DIR / "logs"
LOG_DIR.mkdir(exist_ok=True)

# ============================================================
# LOGGING
# ============================================================
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
log_file  = LOG_DIR / f"dbt_run_{timestamp}.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)s  %(message)s",
    handlers=[
        logging.FileHandler(log_file, encoding="utf-8"),
        logging.StreamHandler()          # affiche aussi dans le terminal
    ]
)
log = logging.getLogger(__name__)

# ============================================================
# FONCTIONS
# ============================================================

def run_command(cmd: list[str]) -> tuple[int, str, str]:
    """Lance une commande shell et retourne (code_retour, stdout, stderr)."""
    log.info(f"Lancement : {' '.join(cmd)}")
    result = subprocess.run(
        cmd,
        cwd=DBT_PROJECT_DIR,
        capture_output=True,
        text=True,
        encoding="utf-8"
    )
    return result.returncode, result.stdout, result.stderr


def build_email_html(
    statut: str,
    duree: str,
    run_output: str,
    test_output: str,
    run_ok: bool,
    test_ok: bool,
    log_path: str
) -> str:
    """Construit le corps HTML du mail de notification."""

    couleur_statut = "#22c55e" if statut == "SUCCÈS" else "#ef4444"
    emoji_statut   = "✅" if statut == "SUCCÈS" else "❌"

    def badge(ok: bool) -> str:
        if ok:
            return '<span style="background:#22c55e;color:#fff;padding:2px 8px;border-radius:4px;font-size:12px;">OK</span>'
        return '<span style="background:#ef4444;color:#fff;padding:2px 8px;border-radius:4px;font-size:12px;">ERREUR</span>'

    html = f"""
    <html><body style="font-family:sans-serif;background:#f8fafc;padding:24px;">
    <div style="max-width:640px;margin:0 auto;background:#fff;border-radius:10px;
                border:1px solid #e2e8f0;overflow:hidden;">

      <!-- EN-TÊTE -->
      <div style="background:{couleur_statut};padding:20px 28px;">
        <h2 style="color:#fff;margin:0;font-size:20px;">
          {emoji_statut} DBT Pipeline DXC — {statut}
        </h2>
        <p style="color:rgba(255,255,255,0.85);margin:6px 0 0;font-size:13px;">
          {datetime.now().strftime("%d/%m/%Y à %H:%M:%S")} · Durée totale : {duree}
        </p>
      </div>

      <!-- RÉSUMÉ -->
      <div style="padding:20px 28px;border-bottom:1px solid #e2e8f0;">
        <table style="width:100%;border-collapse:collapse;">
          <tr>
            <td style="padding:8px 0;color:#64748b;font-size:13px;">dbt run</td>
            <td style="text-align:right;">{badge(run_ok)}</td>
          </tr>
          <tr>
            <td style="padding:8px 0;color:#64748b;font-size:13px;">dbt test</td>
            <td style="text-align:right;">{badge(test_ok)}</td>
          </tr>
          <tr>
            <td style="padding:8px 0;color:#64748b;font-size:13px;">Fichier log</td>
            <td style="text-align:right;font-family:monospace;font-size:11px;color:#475569;">
              {log_path}
            </td>
          </tr>
        </table>
      </div>

      <!-- SORTIE DBT RUN -->
      <div style="padding:20px 28px;border-bottom:1px solid #e2e8f0;">
        <p style="font-weight:600;margin:0 0 10px;color:#1e293b;">
          Détail — dbt run
        </p>
        <pre style="background:#0f172a;color:#e2e8f0;padding:14px;border-radius:6px;
                    font-size:11px;overflow-x:auto;white-space:pre-wrap;">{run_output[-3000:]}</pre>
      </div>

      <!-- SORTIE DBT TEST -->
      <div style="padding:20px 28px;">
        <p style="font-weight:600;margin:0 0 10px;color:#1e293b;">
          Détail — dbt test
        </p>
        <pre style="background:#0f172a;color:#e2e8f0;padding:14px;border-radius:6px;
                    font-size:11px;overflow-x:auto;white-space:pre-wrap;">{test_output[-2000:]}</pre>
      </div>

    </div>
    </body></html>
    """
    return html


def envoyer_mail(sujet: str, corps_html: str) -> None:
    """Envoie un mail via Gmail SMTP."""
    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = sujet
        msg["From"]    = GMAIL_USER
        msg["To"]      = DESTINATAIRE
        msg.attach(MIMEText(corps_html, "html", "utf-8"))

        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as serveur:
            serveur.login(GMAIL_USER, GMAIL_PASSWORD)
            serveur.sendmail(GMAIL_USER, DESTINATAIRE, msg.as_string())

        log.info(f"Mail envoyé à {DESTINATAIRE}")

    except Exception as e:
        log.error(f"Échec envoi mail : {e}")


# ============================================================
# MAIN
# ============================================================

def main():
    debut = datetime.now()
    log.info("=" * 60)
    log.info("DÉBUT DU PIPELINE DBT DXC")
    log.info("=" * 60)

    # 1. dbt run
    run_code, run_stdout, run_stderr = run_command(DBT_COMMAND)
    run_ok = (run_code == 0)
    run_output = run_stdout + ("\n" + run_stderr if run_stderr else "")

    if run_ok:
        log.info("dbt run : SUCCÈS")
    else:
        log.error("dbt run : ERREUR")
        log.error(run_stderr)

    # 2. dbt test (même si run a échoué, pour avoir l'info complète)
    test_code, test_stdout, test_stderr = run_command(DBT_TEST)
    test_ok = (test_code == 0)
    test_output = test_stdout + ("\n" + test_stderr if test_stderr else "")

    if test_ok:
        log.info("dbt test : SUCCÈS")
    else:
        log.error("dbt test : ERREUR")
        log.error(test_stderr)

    # 3. Calcul durée
    duree_sec = (datetime.now() - debut).seconds
    duree_str = f"{duree_sec // 60}m {duree_sec % 60}s"

    # 4. Statut global
    tout_ok  = run_ok and test_ok
    statut   = "SUCCÈS" if tout_ok else "ERREUR"
    emoji    = "✅" if tout_ok else "❌"

    log.info(f"Pipeline terminé en {duree_str} — Statut : {statut}")
    log.info("=" * 60)

    # 5. Envoi mail
    sujet     = f"{emoji} DBT DXC — {statut} ({duree_str}) — {datetime.now().strftime('%d/%m/%Y %H:%M')}"
    corps     = build_email_html(
        statut, duree_str,
        run_output, test_output,
        run_ok, test_ok,
        str(log_file)
    )
    envoyer_mail(sujet, corps)


if __name__ == "__main__":
    main()