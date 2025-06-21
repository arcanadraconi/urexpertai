
export function FeaturesPanel() {
  return (
    <div className="hidden lg:flex lg:w-1/2 gradient-primary p-12 flex-col justify-between mx-auto text-white">
      <div>
        <nav className="flex space-x-6 mx-auto justify-center text-xl">
          <a href="#features" className="nav-link">Features</a>
          <a href="#subscription" className="nav-link">Subscription</a>
          <a href="#how-it-works" className="nav-link">How it works</a>
          <a href="#api" className="nav-link">API</a>
        </nav>
      </div>

      <div className="space-y-24">
        <div className="text-center">
          <h1 className="text-7xl font-medium mb-3">
            <span className="text-[#001426]">Revolutionizing </span>
            Healthcare
          </h1>
          <p className="text-2xl text-center font-normal max-w-4xl mx-auto">
            A cutting-edge, HIPAA-compliant platform for streamlining, analyzing,<br />
            and optimizing medical decision-making with end-to-end encryption.
          </p>
        </div>

        <div className="grid grid-cols-2 gap-6 text-md justify-center mt-16 shadow-md rounded-lg bg-[#001426]/40 mx-8 p-8">
          <ul className="space-y-3">
            <li>✓ Patient Review Generation</li>
            <li>✓ Dark/Light Theme Option</li>
            <li>✓ Secure Data Encryption</li>
            <li>✓ User Dashboard</li>
            <li>✓ AI Integration for Patient Summaries</li>
          </ul>
          <ul className="space-y-3">
            <li>✓ Multi-User Account Management</li>
            <li>✓ Advanced Analytics</li>
            <li>✓ Theme Personalization</li>
            <li>✓ Collaboration Tools</li>
            <li>✓ Role-Based Access Control</li>
          </ul>
        </div>
      </div>

      <div className="text-sm opacity-70 mx-auto justify-center">
        © 2024 URExpert. All rights reserved.
      </div>
    </div>
  );
}