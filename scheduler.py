import time
import schedule
from sqlalchemy import text
from app.lib.sql_controller import controller_analytical

def run_etl_job():

    try:
        with controller_analytical.engine.connect() as conn:
            conn.execute(text("CALL analytical.batch_update_dw_incremental();"))
            conn.commit()
        print("[Scheduler] Success.")
    except Exception as e:
        print(f"[Scheduler] Failed: {e}")

schedule.every().day.at("03:00").do(run_etl_job)

if __name__ == "__main__":
    print("[Scheduler] Service Started.")

    print("[Scheduler] Initial run.")
    run_etl_job() 

    
    while True:
        schedule.run_pending()
        time.sleep(60)