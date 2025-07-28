import streamlit as st
import pandas as pd
import pycountry

# Set page config
st.set_page_config(
    page_title="Client Data Questionnaire",
    page_icon="🏨",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS for modern design with blue and yellow theme
st.markdown("""
<style>
    .main {
        padding-top: 2rem;
    }
    
    .stSelectbox > div > div > select {
        background-color: #E8F4FD;
        border: 2px solid #4A90E2;
    }
    
    .stFileUploader > div > div {
        background-color: #FFF9E6;
        border: 2px solid #FFD700;
        border-radius: 10px;
        padding: 20px;
    }
    
    .metric-card {
        background: linear-gradient(135deg, #4A90E2 0%, #357ABD 100%);
        padding: 20px;
        border-radius: 15px;
        color: white;
        text-align: center;
        margin: 10px 0;
    }
    
    .result-card {
        background: linear-gradient(135deg, #FFD700 0%, #FFC107 100%);
        padding: 20px;
        border-radius: 15px;
        color: #333;
        margin: 10px 0;
    }
    
    .header-style {
        background: linear-gradient(90deg, #1E3A8A 0%, #3B82F6 50%, #FFD700 100%);
        padding: 20px;
        border-radius: 15px;
        text-align: center;
        color: white;
        margin-bottom: 30px;
    }
</style>
""", unsafe_allow_html=True)

# Header
st.markdown('<div class="header-style"><h1>🏨 Client Data Collection Questionnaire</h1></div>', unsafe_allow_html=True)

# Initialize session state
if 'form_submitted' not in st.session_state:
    st.session_state.form_submitted = False

# Create columns for layout
col1, col2 = st.columns([2, 1])

with col1:
    st.markdown("### 📊 Configuration Settings")
    
    # 1. Hotel Quantity Selection
    st.markdown("#### 1. Number of Hotels in Template")
    hotel_quantity = st.selectbox(
        "Select the quantity of hotels:",
        options=[2500, 5000, 10000],
        index=0,
        help="Choose the number of hotels to include in your template"
    )
    
    # Display selected quantity in a metric card
    st.markdown(f'<div class="metric-card"><h3>{hotel_quantity:,}</h3><p>Hotels Selected</p></div>', unsafe_allow_html=True)
    
    # 2. Country Selection
    st.markdown("#### 2. Top Destinations")
    
    # Get list of all countries
    countries = [country.name for country in pycountry.countries]
    countries.sort()
    
    selected_countries = st.multiselect(
        "Search and select destination countries:",
        options=countries,
        default=["United States", "United Kingdom", "France", "Germany", "Spain"],
        help="You can search and select multiple countries"
    )
    
    # 3. CSV File Upload
    st.markdown("#### 3. Hotel ID Upload")
    uploaded_file = st.file_uploader(
        "Upload CSV file with Hotel IDs (single column)",
        type=['csv'],
        help="Upload a CSV file containing a single column with Hotel IDs"
    )
    
    # Process uploaded file
    if uploaded_file is not None:
        try:
            df = pd.read_csv(uploaded_file)
            
            if len(df.columns) == 1:
                hotel_ids = df.iloc[:, 0].tolist()
                top_1000_hotels = hotel_ids[:1000] if len(hotel_ids) > 1000 else hotel_ids
                
                st.success(f"✅ File uploaded successfully! Found {len(hotel_ids)} Hotel IDs")
                st.info(f"📈 Displaying top {len(top_1000_hotels)} hotels")
                
                # Show preview of hotel IDs
                with st.expander("Preview Hotel IDs"):
                    preview_df = pd.DataFrame(top_1000_hotels[:10], columns=['Hotel ID'])
                    st.dataframe(preview_df)
                    
            else:
                st.error("❌ Please upload a CSV file with exactly one column containing Hotel IDs")
                
        except Exception as e:
            st.error(f"❌ Error reading file: {str(e)}")

with col2:
    st.markdown("### 📋 Summary")
    
    # Summary card
    st.markdown(f"""
    <div class="result-card">
        <h4>📊 Current Selection</h4>
        <p><strong>Hotels:</strong> {hotel_quantity:,}</p>
        <p><strong>Countries:</strong> {len(selected_countries)}</p>
        <p><strong>File Status:</strong> {'✅ Uploaded' if uploaded_file else '⏳ Pending'}</p>
    </div>
    """, unsafe_allow_html=True)
    
    # Selected countries display
    if selected_countries:
        st.markdown("#### 🌍 Selected Countries")
        for country in selected_countries[:10]:  # Show first 10
            st.markdown(f"• {country}")
        if len(selected_countries) > 10:
            st.markdown(f"... and {len(selected_countries) - 10} more")

# Submit button
st.markdown("---")
col_submit1, col_submit2, col_submit3 = st.columns([1, 2, 1])

with col_submit2:
    if st.button("🚀 Submit Questionnaire", use_container_width=True):
        if selected_countries and (uploaded_file is not None):
            st.session_state.form_submitted = True
            st.balloons()
            
            # Create results summary
            st.markdown("""
            <div class="result-card">
                <h3>✅ Questionnaire Submitted Successfully!</h3>
                <p>Your hotel data collection parameters have been recorded.</p>
            </div>
            """, unsafe_allow_html=True)
            
            # Show final summary
            summary_data = {
                "Parameter": ["Hotel Quantity", "Selected Countries", "Uploaded Hotel IDs"],
                "Value": [
                    f"{hotel_quantity:,}",
                    f"{len(selected_countries)} countries",
                    f"{len(top_1000_hotels) if uploaded_file else 0} hotels"
                ]
            }
            
            st.markdown("#### 📊 Final Summary")
            st.dataframe(pd.DataFrame(summary_data), use_container_width=True)
            
        else:
            st.error("❌ Please complete all required fields: select countries and upload a CSV file")

# Footer
st.markdown("---")
st.markdown(
    """
    <div style="text-align: center; color: #666; padding: 20px;">
        🏨 Client Data Collection System | Built with Streamlit
    </div>
    """, 
    unsafe_allow_html=True
)