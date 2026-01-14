console.log('Script loaded!'); // Verify script is loading

// Get modal elements (declared globally so they can be used everywhere)
const providerModal = document.getElementById('providerModal');
const clientModal = document.getElementById('clientModal');

console.log('Provider Modal:', providerModal); // Debug log
console.log('Client Modal:', clientModal); // Debug log

// Smooth Scroll
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Navbar Scroll Effect
window.addEventListener('scroll', () => {
    const navbar = document.querySelector('.navbar');
    if (window.scrollY > 50) {
        navbar.classList.add('scrolled');
    } else {
        navbar.classList.remove('scrolled');
    }
});

// Mobile Menu Toggle
const mobileMenuBtn = document.querySelector('.mobile-menu-btn');
const navLinks = document.querySelector('.nav-links');

mobileMenuBtn?.addEventListener('click', () => {
    navLinks.classList.toggle('active');
    mobileMenuBtn.classList.toggle('active');
});

// Modal Functionality
document.querySelectorAll('.open-provider-modal').forEach(btn => {
    console.log('Found provider button:', btn); // Debug log
    btn.addEventListener('click', (e) => {
        e.preventDefault();
        console.log('Provider button clicked'); // Debug log
        if (providerModal) {
            providerModal.classList.add('active');
            console.log('Modal class added, active class list:', providerModal.classList);
        }
    });
});

document.querySelectorAll('.open-client-modal').forEach(btn => {
    console.log('Found client button:', btn); // Debug log
    btn.addEventListener('click', (e) => {
        e.preventDefault();
        console.log('Client button clicked'); // Debug log
        if (clientModal) {
            clientModal.classList.add('active');
            console.log('Modal class added, active class list:', clientModal.classList);
        }
    });
});

document.querySelectorAll('.modal-close').forEach(closeBtn => {
    closeBtn.addEventListener('click', () => {
        if (providerModal) providerModal.classList.remove('active');
        if (clientModal) clientModal.classList.remove('active');
    });
});

// Close modal when clicking outside
window.addEventListener('click', (e) => {
    if (e.target === providerModal) {
        providerModal.classList.remove('active');
    }
    if (e.target === clientModal) {
        clientModal.classList.remove('active');
    }
});

// Fade-in Animation on Scroll
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Observe all sections
document.querySelectorAll('.section').forEach(section => {
    section.style.opacity = '0';
    section.style.transform = 'translateY(30px)';
    section.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
    observer.observe(section);
});

// Stats Counter Animation
const animateCounter = (element, target) => {
    let current = 0;
    const increment = target / 100;
    const timer = setInterval(() => {
        current += increment;
        if (current >= target) {
            element.textContent = target + '+';
            clearInterval(timer);
        } else {
            element.textContent = Math.floor(current) + '+';
        }
    }, 20);
};

const statsObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const statNumber = entry.target.querySelector('.stat-number');
            const targetText = statNumber.textContent;
            const targetNumber = parseInt(targetText);
            if (!isNaN(targetNumber)) {
                animateCounter(statNumber, targetNumber);
            }
            statsObserver.unobserve(entry.target);
        }
    });
}, observerOptions);

document.querySelectorAll('.social-proof .stat').forEach(stat => {
    statsObserver.observe(stat);
});

// Console Easter Egg
console.log('%cHireMeBuddy', 'font-size: 24px; font-weight: bold; color: #14B8A6;');
console.log('%cMade in Namibia', 'font-size: 14px; color: #64748b;');
console.log('%cInterested in joining our team? Email info@hiremebuddy.app', 'font-size: 12px; color: #0D9488;');

// Waitlist Form Submission
const SUPABASE_URL = 'https://vjpaolkqlumpyuxxmmvr.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqcGFvbGtxbHVtcHl1eHhtbXZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI5MTY3ODEsImV4cCI6MjA2ODQ5Mjc4MX0.irmIx87eljdUN5zdu3IH5aQbUxAgGbjS8d4ENgBg2Tc';

async function submitWaitlist(formData, userType, messageElement, submitButton) {
    const originalButtonText = submitButton.textContent;
    submitButton.disabled = true;
    submitButton.textContent = 'Submitting...';
    messageElement.className = 'form-message';
    messageElement.style.display = 'none';

    try {
        const response = await fetch(`${SUPABASE_URL}/rest/v1/waitlist`, {
            method: 'POST',
            headers: {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                'Content-Type': 'application/json',
                'Prefer': 'return=minimal'
            },
            body: JSON.stringify({
                email: formData.email,
                full_name: formData.full_name || null,
                phone_number: formData.phone_number || null,
                user_type: userType
            })
        });

        if (response.ok || response.status === 201) {
            messageElement.className = 'form-message success';
            messageElement.textContent = '🎉 Success! You\'ve been added to our waiting list. We\'ll notify you soon!';
            messageElement.style.display = 'block';
            
            // Reset form
            document.getElementById(`${userType}WaitlistForm`).reset();
            
            // Close modal after 3 seconds
            setTimeout(() => {
                if (userType === 'provider') {
                    providerModal.classList.remove('active');
                } else {
                    clientModal.classList.remove('active');
                }
                messageElement.style.display = 'none';
            }, 3000);
        } else {
            const errorData = await response.json();
            
            // Check if it's a duplicate email error
            if (errorData.message && errorData.message.includes('duplicate') || errorData.message && errorData.message.includes('unique')) {
                messageElement.className = 'form-message error';
                messageElement.textContent = 'This email is already on our waiting list!';
            } else {
                messageElement.className = 'form-message error';
                messageElement.textContent = 'Oops! Something went wrong. Please try again.';
            }
            messageElement.style.display = 'block';
        }
    } catch (error) {
        console.error('Waitlist submission error:', error);
        messageElement.className = 'form-message error';
        messageElement.textContent = 'Network error. Please check your connection and try again.';
        messageElement.style.display = 'block';
    } finally {
        submitButton.disabled = false;
        submitButton.textContent = originalButtonText;
    }
}

// Provider Waitlist Form
const providerWaitlistForm = document.getElementById('providerWaitlistForm');
const providerMessage = document.getElementById('provider-message');

providerWaitlistForm?.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const formData = {
        email: document.getElementById('provider-email').value.trim(),
        full_name: document.getElementById('provider-name').value.trim(),
        phone_number: document.getElementById('provider-phone').value.trim()
    };
    
    const submitButton = providerWaitlistForm.querySelector('button[type="submit"]');
    await submitWaitlist(formData, 'provider', providerMessage, submitButton);
});

// Client Waitlist Form
const clientWaitlistForm = document.getElementById('clientWaitlistForm');
const clientMessage = document.getElementById('client-message');

clientWaitlistForm?.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const formData = {
        email: document.getElementById('client-email').value.trim(),
        full_name: document.getElementById('client-name').value.trim(),
        phone_number: document.getElementById('client-phone').value.trim()
    };
    
    const submitButton = clientWaitlistForm.querySelector('button[type="submit"]');
    await submitWaitlist(formData, 'client', clientMessage, submitButton);
});
