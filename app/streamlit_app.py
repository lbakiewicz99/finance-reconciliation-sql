from pathlib import Path

import pandas as pandas
import streamlit as streamlit


streamlit.set_page_config(
    page_title="Finance Reconciliation Dashboard",
    page_icon="💼",
    layout="wide",
)


PROJECT_ROOT_PATH = Path(__file__).resolve().parents[1]
OUTPUT_EXAMPLES_PATH = PROJECT_ROOT_PATH / "output_examples"

OPEN_BREAKS_FILE_PATH = OUTPUT_EXAMPLES_PATH / "open_breaks_example.csv"
AGED_EXCEPTIONS_FILE_PATH = OUTPUT_EXAMPLES_PATH / "aged_exceptions_example.csv"
MATCHED_TRANSACTIONS_FILE_PATH = OUTPUT_EXAMPLES_PATH / "matched_transactions_example.csv"
MONTHLY_SUMMARY_FILE_PATH = OUTPUT_EXAMPLES_PATH / "monthly_summary_example.csv"


COLUMN_CANDIDATES = {
    "exception_code": [
        "exception_code",
        "exception_type_code",
        "exception_type",
        "break_type",
    ],
    "priority": [
        "priority",
        "priority_level",
        "exception_priority",
    ],
    "break_status": [
        "break_status",
        "status",
        "reconciliation_status",
        "result_status",
    ],
    "aging_bucket": [
        "aging_bucket",
        "age_bucket",
    ],
    "month": [
        "reconciliation_month",
        "reporting_month",
        "month",
        "run_month",
        "period_month",
    ],
    "monthly_status": [
        "result_status",
        "reconciliation_status",
        "break_status",
        "status",
    ],
    "monthly_count": [
        "transaction_count",
        "result_count",
        "record_count",
        "count",
        "total_count",
        "number_of_transactions",
    ],
}


def render_page_styles() -> None:
    streamlit.markdown(
        """
        <style>
            .block-container {
                padding-top: 2rem;
                padding-bottom: 2rem;
            }

            div[data-testid="stMetric"] {
                background: #111827;
                border: 1px solid #374151;
                padding: 1rem;
                border-radius: 0.75rem;
            }

            div[data-testid="stMetricLabel"] p {
                color: #d1d5db !important;
                font-size: 0.9rem;
                font-weight: 600;
            }

            div[data-testid="stMetricValue"] {
                color: #f9fafb !important;
                font-weight: 700;
            }

            div[data-testid="stMetricDelta"] {
                color: #9ca3af !important;
            }
        </style>
        """,
        unsafe_allow_html=True,
    )


@streamlit.cache_data(show_spinner=False)
def load_csv_file(file_path: Path) -> pandas.DataFrame:
    if not file_path.exists():
        return pandas.DataFrame()

    try:
        dataframe = pandas.read_csv(file_path)
    except pandas.errors.EmptyDataError:
        return pandas.DataFrame()

    dataframe.columns = [str(column_name).strip() for column_name in dataframe.columns]

    for column_name in dataframe.columns:
        if dataframe[column_name].dtype == "object":
            dataframe[column_name] = dataframe[column_name].apply(
                lambda value: value.strip() if isinstance(value, str) else value
            )

    return dataframe


def get_existing_column(
    dataframe: pandas.DataFrame,
    candidate_column_names: list[str],
) -> str | None:
    dataframe_columns_lowercase = {
        column_name.lower(): column_name
        for column_name in dataframe.columns
    }

    for candidate_column_name in candidate_column_names:
        matching_column_name = dataframe_columns_lowercase.get(
            candidate_column_name.lower()
        )

        if matching_column_name is not None:
            return matching_column_name

    return None


def get_unique_sorted_values(
    dataframe: pandas.DataFrame,
    column_name: str,
) -> list[str]:
    if dataframe.empty or column_name not in dataframe.columns:
        return []

    values = (
        dataframe[column_name]
        .dropna()
        .astype(str)
        .str.strip()
    )

    values = values[values != ""]

    return sorted(values.unique().tolist())


def apply_multiselect_filter(
    dataframe: pandas.DataFrame,
    column_name: str | None,
    label: str,
    widget_key: str,
) -> pandas.DataFrame:
    if dataframe.empty or column_name is None:
        return dataframe

    available_values = get_unique_sorted_values(
        dataframe=dataframe,
        column_name=column_name,
    )

    if not available_values:
        return dataframe

    selected_values = streamlit.multiselect(
        label=label,
        options=available_values,
        default=available_values,
        key=widget_key,
    )

    if not selected_values:
        return dataframe.iloc[0:0]

    return dataframe[dataframe[column_name].astype(str).isin(selected_values)]


def count_high_priority_breaks(open_breaks_dataframe: pandas.DataFrame) -> int:
    priority_column_name = get_existing_column(
        dataframe=open_breaks_dataframe,
        candidate_column_names=COLUMN_CANDIDATES["priority"],
    )

    if priority_column_name is None:
        return 0

    high_priority_values = {
        "HIGH",
        "CRITICAL",
        "URGENT",
        "P1",
        "HIGH PRIORITY",
    }

    priority_series = (
        open_breaks_dataframe[priority_column_name]
        .fillna("")
        .astype(str)
        .str.upper()
        .str.replace("_", " ", regex=False)
        .str.strip()
    )

    return int(priority_series.isin(high_priority_values).sum())


def count_reference_mismatches(open_breaks_dataframe: pandas.DataFrame) -> int:
    exception_code_column_name = get_existing_column(
        dataframe=open_breaks_dataframe,
        candidate_column_names=COLUMN_CANDIDATES["exception_code"],
    )

    if exception_code_column_name is None:
        return 0

    exception_code_series = (
        open_breaks_dataframe[exception_code_column_name]
        .fillna("")
        .astype(str)
        .str.upper()
        .str.strip()
    )

    return int((exception_code_series == "REFERENCE_MISMATCH").sum())


def render_kpi_cards(
    open_breaks_dataframe: pandas.DataFrame,
    aged_exceptions_dataframe: pandas.DataFrame,
    matched_transactions_dataframe: pandas.DataFrame,
) -> None:
    open_breaks_count = len(open_breaks_dataframe)
    aged_exceptions_count = len(aged_exceptions_dataframe)
    high_priority_breaks_count = count_high_priority_breaks(
        open_breaks_dataframe=open_breaks_dataframe
    )
    reference_mismatches_count = count_reference_mismatches(
        open_breaks_dataframe=open_breaks_dataframe
    )
    matched_transactions_count = len(matched_transactions_dataframe)

    kpi_columns = streamlit.columns(5)

    kpi_columns[0].metric("Open Breaks", f"{open_breaks_count:,}")
    kpi_columns[1].metric("Aged Exceptions", f"{aged_exceptions_count:,}")
    kpi_columns[2].metric("High Priority Breaks", f"{high_priority_breaks_count:,}")
    kpi_columns[3].metric("Reference Mismatches", f"{reference_mismatches_count:,}")
    kpi_columns[4].metric("Matched Transactions", f"{matched_transactions_count:,}")


def render_missing_file_warnings(
    loaded_files: dict[str, pandas.DataFrame],
) -> None:
    missing_file_names = [
        file_name
        for file_name, dataframe in loaded_files.items()
        if dataframe.empty
    ]

    if missing_file_names:
        streamlit.warning(
            "Some CSV files are missing or empty: "
            + ", ".join(missing_file_names)
            + ". The dashboard will still render the available sections."
        )


def render_monthly_summary(monthly_summary_dataframe: pandas.DataFrame) -> None:
    streamlit.subheader("Monthly Reconciliation Summary")
    streamlit.caption(
        "Business view: this shows how reconciliation outcomes change by period, "
        "which helps spot control deterioration or improvement month over month."
    )

    if monthly_summary_dataframe.empty:
        streamlit.info("No monthly summary CSV data available.")
        return

    streamlit.dataframe(
        monthly_summary_dataframe,
        use_container_width=True,
        hide_index=True,
    )


def render_result_mix_chart(monthly_summary_dataframe: pandas.DataFrame) -> None:
    streamlit.subheader("Result Mix by Month")

    if monthly_summary_dataframe.empty:
        streamlit.info("No monthly summary CSV data available for the chart.")
        return

    month_column_name = get_existing_column(
        dataframe=monthly_summary_dataframe,
        candidate_column_names=COLUMN_CANDIDATES["month"],
    )

    if month_column_name is None:
        streamlit.info("Month column not found in monthly_summary_example.csv.")
        return

    result_mix_column_names = [
        "matched_count",
        "unmatched_count",
        "mismatch_count",
        "duplicate_count",
    ]

    available_result_mix_column_names = [
        column_name
        for column_name in result_mix_column_names
        if column_name in monthly_summary_dataframe.columns
    ]

    if not available_result_mix_column_names:
        streamlit.info(
            "Result mix count columns were not found in monthly_summary_example.csv."
        )
        return

    chart_dataframe = monthly_summary_dataframe[
        [month_column_name] + available_result_mix_column_names
    ].copy()

    chart_dataframe[month_column_name] = pandas.to_datetime(
        chart_dataframe[month_column_name],
        errors="coerce",
    ).dt.strftime("%Y-%m")

    chart_dataframe = chart_dataframe.dropna(subset=[month_column_name])

    chart_dataframe = chart_dataframe.rename(
        columns={
            "matched_count": "Matched",
            "unmatched_count": "Unmatched",
            "mismatch_count": "Mismatch",
            "duplicate_count": "Duplicate",
        }
    )

    chart_dataframe = chart_dataframe.set_index(month_column_name).sort_index()

    streamlit.bar_chart(chart_dataframe)


def render_open_breaks_section(
    open_breaks_dataframe: pandas.DataFrame,
) -> pandas.DataFrame:
    streamlit.subheader("Open Breaks")
    streamlit.caption(
        "Business view: unresolved exceptions represent operational risk, cash breaks, "
        "or records requiring manual investigation."
    )

    if open_breaks_dataframe.empty:
        streamlit.info("No open breaks CSV data available.")
        return open_breaks_dataframe

    exception_code_column_name = get_existing_column(
        dataframe=open_breaks_dataframe,
        candidate_column_names=COLUMN_CANDIDATES["exception_code"],
    )
    priority_column_name = get_existing_column(
        dataframe=open_breaks_dataframe,
        candidate_column_names=COLUMN_CANDIDATES["priority"],
    )
    break_status_column_name = get_existing_column(
        dataframe=open_breaks_dataframe,
        candidate_column_names=COLUMN_CANDIDATES["break_status"],
    )

    filter_columns = streamlit.columns(3)

    with filter_columns[0]:
        filtered_open_breaks_dataframe = apply_multiselect_filter(
            dataframe=open_breaks_dataframe,
            column_name=exception_code_column_name,
            label="Exception code",
            widget_key="open_breaks_exception_code_filter",
        )

    with filter_columns[1]:
        filtered_open_breaks_dataframe = apply_multiselect_filter(
            dataframe=filtered_open_breaks_dataframe,
            column_name=priority_column_name,
            label="Priority",
            widget_key="open_breaks_priority_filter",
        )

    with filter_columns[2]:
        filtered_open_breaks_dataframe = apply_multiselect_filter(
            dataframe=filtered_open_breaks_dataframe,
            column_name=break_status_column_name,
            label="Break status",
            widget_key="open_breaks_break_status_filter",
        )

    streamlit.dataframe(
        filtered_open_breaks_dataframe,
        use_container_width=True,
        hide_index=True,
    )

    return filtered_open_breaks_dataframe


def render_open_breaks_by_exception_type_chart(
    open_breaks_dataframe: pandas.DataFrame,
) -> None:
    streamlit.subheader("Open Breaks by Exception Type")

    if open_breaks_dataframe.empty:
        streamlit.info("No open breaks data available for the chart.")
        return

    exception_code_column_name = get_existing_column(
        dataframe=open_breaks_dataframe,
        candidate_column_names=COLUMN_CANDIDATES["exception_code"],
    )

    if exception_code_column_name is None:
        streamlit.info("Exception code column not found in open_breaks_example.csv.")
        return

    chart_dataframe = (
        open_breaks_dataframe[exception_code_column_name]
        .fillna("UNKNOWN")
        .astype(str)
        .value_counts()
        .rename_axis("exception_code")
        .reset_index(name="break_count")
        .set_index("exception_code")
    )

    streamlit.bar_chart(chart_dataframe)


def render_aged_exceptions_section(
    aged_exceptions_dataframe: pandas.DataFrame,
) -> pandas.DataFrame:
    streamlit.subheader("Aged Exceptions")
    streamlit.caption(
        "Business view: aged breaks are exceptions that breached the aging threshold. "
        "They are usually the items a team lead, controller, or operations manager "
        "wants escalated first."
    )

    if aged_exceptions_dataframe.empty:
        streamlit.info("No aged exceptions CSV data available.")
        return aged_exceptions_dataframe

    aging_bucket_column_name = get_existing_column(
        dataframe=aged_exceptions_dataframe,
        candidate_column_names=COLUMN_CANDIDATES["aging_bucket"],
    )
    priority_column_name = get_existing_column(
        dataframe=aged_exceptions_dataframe,
        candidate_column_names=COLUMN_CANDIDATES["priority"],
    )

    filter_columns = streamlit.columns(2)

    with filter_columns[0]:
        filtered_aged_exceptions_dataframe = apply_multiselect_filter(
            dataframe=aged_exceptions_dataframe,
            column_name=aging_bucket_column_name,
            label="Aging bucket",
            widget_key="aged_exceptions_aging_bucket_filter",
        )

    with filter_columns[1]:
        filtered_aged_exceptions_dataframe = apply_multiselect_filter(
            dataframe=filtered_aged_exceptions_dataframe,
            column_name=priority_column_name,
            label="Priority",
            widget_key="aged_exceptions_priority_filter",
        )

    streamlit.dataframe(
        filtered_aged_exceptions_dataframe,
        use_container_width=True,
        hide_index=True,
    )

    return filtered_aged_exceptions_dataframe


def render_aged_exceptions_by_aging_bucket_chart(
    aged_exceptions_dataframe: pandas.DataFrame,
) -> None:
    streamlit.subheader("Aged Exceptions by Aging Bucket")

    if aged_exceptions_dataframe.empty:
        streamlit.info("No aged exceptions data available for the chart.")
        return

    aging_bucket_column_name = get_existing_column(
        dataframe=aged_exceptions_dataframe,
        candidate_column_names=COLUMN_CANDIDATES["aging_bucket"],
    )

    if aging_bucket_column_name is None:
        streamlit.info("Aging bucket column not found in aged_exceptions_example.csv.")
        return

    chart_dataframe = (
        aged_exceptions_dataframe[aging_bucket_column_name]
        .fillna("UNKNOWN")
        .astype(str)
        .value_counts()
        .rename_axis("aging_bucket")
        .reset_index(name="exception_count")
        .set_index("aging_bucket")
    )

    streamlit.bar_chart(chart_dataframe)


def render_matched_transactions_section(
    matched_transactions_dataframe: pandas.DataFrame,
) -> None:
    streamlit.subheader("Matched Transactions")
    streamlit.caption(
        "Business view: matched records prove that internal system activity agrees "
        "with external statement data after applying normalized reference logic."
    )

    if matched_transactions_dataframe.empty:
        streamlit.info("No matched transactions CSV data available.")
        return

    streamlit.dataframe(
        matched_transactions_dataframe,
        use_container_width=True,
        hide_index=True,
    )


def render_methodology_notes() -> None:
    streamlit.subheader("Methodology Notes")
    streamlit.markdown(
        """
        - The dashboard reads exported CSV files from `output_examples/`.
        - PostgreSQL remains the source of truth for the reconciliation logic.
        - Raw transaction references may differ between internal and external systems.
        - Matching is based on normalized `matching_reference` values and supporting transaction attributes.
        - Open breaks, aged exceptions, duplicates, and reference mismatches are intentionally present in the sample data.
        - This UI is a lightweight portfolio layer, not a production case-management application.
        """
    )


def main() -> None:
    render_page_styles()

    streamlit.title("Finance Reconciliation Dashboard")
    streamlit.caption(
        "Lightweight UI for reviewing reconciliation outputs generated by the SQL project."
    )

    open_breaks_dataframe = load_csv_file(OPEN_BREAKS_FILE_PATH)
    aged_exceptions_dataframe = load_csv_file(AGED_EXCEPTIONS_FILE_PATH)
    matched_transactions_dataframe = load_csv_file(MATCHED_TRANSACTIONS_FILE_PATH)
    monthly_summary_dataframe = load_csv_file(MONTHLY_SUMMARY_FILE_PATH)

    loaded_files = {
        "open_breaks_example.csv": open_breaks_dataframe,
        "aged_exceptions_example.csv": aged_exceptions_dataframe,
        "matched_transactions_example.csv": matched_transactions_dataframe,
        "monthly_summary_example.csv": monthly_summary_dataframe,
    }

    render_missing_file_warnings(loaded_files=loaded_files)

    with streamlit.sidebar:
        streamlit.header("Data Source")
        streamlit.write("CSV directory:")
        streamlit.code(str(OUTPUT_EXAMPLES_PATH))

        streamlit.write("Loaded rows:")
        streamlit.dataframe(
            pandas.DataFrame(
                {
                    "file_name": list(loaded_files.keys()),
                    "row_count": [
                        len(dataframe)
                        for dataframe in loaded_files.values()
                    ],
                }
            ),
            use_container_width=True,
            hide_index=True,
        )

    render_kpi_cards(
        open_breaks_dataframe=open_breaks_dataframe,
        aged_exceptions_dataframe=aged_exceptions_dataframe,
        matched_transactions_dataframe=matched_transactions_dataframe,
    )

    streamlit.divider()

    render_monthly_summary(monthly_summary_dataframe=monthly_summary_dataframe)
    render_result_mix_chart(monthly_summary_dataframe=monthly_summary_dataframe)

    streamlit.divider()

    filtered_open_breaks_dataframe = render_open_breaks_section(
        open_breaks_dataframe=open_breaks_dataframe
    )
    render_open_breaks_by_exception_type_chart(
        open_breaks_dataframe=filtered_open_breaks_dataframe
    )

    streamlit.divider()

    filtered_aged_exceptions_dataframe = render_aged_exceptions_section(
        aged_exceptions_dataframe=aged_exceptions_dataframe
    )
    render_aged_exceptions_by_aging_bucket_chart(
        aged_exceptions_dataframe=filtered_aged_exceptions_dataframe
    )

    streamlit.divider()

    render_matched_transactions_section(
        matched_transactions_dataframe=matched_transactions_dataframe
    )

    streamlit.divider()

    render_methodology_notes()


if __name__ == "__main__":
    main()