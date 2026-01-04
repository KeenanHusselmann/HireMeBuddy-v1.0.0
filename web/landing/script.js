// Supabase Configuration
const SUPABASE_URL = 'https://vjpaolkqlumpyuxxmmvr.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqcGFvbGtxbHVtcHl1eHhtbXZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI5MTY3ODEsImV4cCI6MjA2ODQ5Mjc4MX0.irmIx87eljdUN5zdu3IH5aQbUxAgGbjS8d4ENgBg2Tc';

let supabaseClient;

// Initialize Supabase
if (typeof supabase !== 'undefined') {
    supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
}

// Wait for DOM to be fully loaded before initializing modals
document.addEventListener('DOMContentLoaded', () => {
    // Modal Management
    const providerModal = document.getElementById('providerModal');
    const clientModal = document.getElementById('clientModal');
    const providerForm = document.getElementById('providerForm');
    const clientForm = document.getElementById('clientForm');
    const providerSuccess = document.getElementById('providerSuccess');
    const clientSuccess = document.getElementById('clientSuccess');

    // Open modals
    document.querySelectorAll('.open-provider-modal').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.preventDefault();
            providerModal.classList.add('active');
            document.body.style.overflow = 'hidden';
        });
    });

    document.querySelectorAll('.open-client-modal').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.preventDefault();
            clientModal.classList.add('active');
            document.body.style.overflow = 'hidden';
        });
    });

    // Close modals
    document.querySelectorAll('.modal-close').forEach(closeBtn => {
        closeBtn.addEventListener('click', function() {
            this.closest('.modal').classList.remove('active');
            document.body.style.overflow = 'auto';
        });
    });

    // Close modal when clicking outside
    [providerModal, clientModal].forEach(modal => {
        if (modal) {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) {
                    modal.classList.remove('active');
                    document.body.style.overflow = 'auto';
                }
            });
        }
    });

    // Close modal on ESC key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            document.querySelectorAll('.modal.active').forEach(modal => {
                modal.classList.remove('active');
                document.body.style.overflow = 'auto';
            });
        }
    });

    // Form submission handler
    async function handleFormSubmit(form, userType, successElement) {
        const submitBtn = form.querySelector('button[type="submit"]');
        const originalText = submitBtn.textContent;
        
        try {
            submitBtn.disabled = true;
            submitBtn.textContent = 'Submitting...';
            
            const formData = new FormData(form);
            const data = {
                full_name: formData.get('full_name'),
                email: formData.get('email'),
                phone_number: formData.get('phone_number') || null,
                user_type: userType,
                service_category: formData.get('service_category') || null,
                location: formData.get('location') || null,
                message: formData.get('message') || null,
                subscribed_to_updates: formData.get('subscribed_to_updates') === 'on'
            };
            
            if (supabaseClient) {
                // Submit to Supabase
                const { error } = await supabaseClient
                    .from('waiting_list')
                    .insert([data]);
                
                if (error) {
                    if (error.code === '23505') { // Unique constraint violation
                        throw new Error('This email is already registered!');
                    }
                    throw error;
                }
            } else {
                // Fallback: Log to console (for development)
                console.log('Waiting list signup:', data);
                // In production, you might want to send this to a webhook or API
            }
            
            // Show success message
            form.style.display = 'none';
            successElement.style.display = 'block';
            
            // Reset form after delay
            setTimeout(() => {
                form.reset();
                form.style.display = 'flex';
                successElement.style.display = 'none';
                submitBtn.disabled = false;
                submitBtn.textContent = originalText;
                form.closest('.modal').classList.remove('active');
                document.body.style.overflow = 'auto';
            }, 3000);
            
        } catch (error) {
            console.error('Error submitting form:', error);
            alert(error.message || 'Something went wrong. Please try again.');
            submitBtn.disabled = false;
            submitBtn.textContent = originalText;
        }
    }

    // Provider form submission
    if (providerForm) {
        providerForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            await handleFormSubmit(providerForm, 'provider', providerSuccess);
        });
    }

    // Client form submission
    if (clientForm) {
        clientForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            await handleFormSubmit(clientForm, 'client', clientSuccess);
        });
    }
});

// Mobile Menu Toggle
const mobileMenuBtn = document.querySelector('.mobile-menu-btn');
const navLinks = document.querySelector('.nav-links');

mobileMenuBtn?.addEventListener('click', () => {
    navLinks.classList.toggle('active');
    mobileMenuBtn.classList.toggle('active');
});

// Smooth Scroll for Navigation Links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
            // Close mobile menu if open
            navLinks?.classList.remove('active');
            mobileMenuBtn?.classList.remove('active');
        }
    });
});

// Navbar Scroll Effect
let lastScroll = 0;
const navbar = document.querySelector('.navbar');

window.addEventListener('scroll', () => {
    const currentScroll = window.pageYOffset;
    
    if (currentScroll <= 0) {
        navbar.style.boxShadow = 'none';
    } else {
        navbar.style.boxShadow = '0 2px 8px rgba(0, 0, 0, 0.1)';
    }
    
    lastScroll = currentScroll;
});

// Intersection Observer for Fade-in Animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('fade-in');
            observer.unobserve(entry.target);
        }
    });
}, observerOptions);

// Observe all sections
document.querySelectorAll('.section, .hero, .feature-card, .step, .service-card').forEach(el => {
    observer.observe(el);
});

// Stats Counter Animation
const animateCounter = (element, target, duration = 2000) => {
    const start = 0;
    const increment = target / (duration / 16);
    let current = start;
    
    const timer = setInterval(() => {
        current += increment;
        if (current >= target) {
            element.textContent = target.toString().includes('.') ? target : Math.floor(target);
            clearInterval(timer);
        } else {
            element.textContent = Math.floor(current);
        }
    }, 16);
};

// Animate stats when they come into view
const statsObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const statNumber = entry.target.querySelector('.stat-number');
            if (statNumber && !statNumber.classList.contains('animated')) {
                const text = statNumber.textContent;
                const number = parseInt(text.replace(/\D/g, ''));
                if (!isNaN(number)) {
                    statNumber.textContent = '0';
                    animateCounter(statNumber, number);
                    if (text.includes('+')) {
                        statNumber.textContent = statNumber.textContent + '+';
                    }
                    if (text.includes('★')) {
                        statNumber.textContent = text;
                    }
                    statNumber.classList.add('animated');
                }
            }
            statsObserver.unobserve(entry.target);
        }
    });
}, { threshold: 0.5 });

document.querySelectorAll('.stat').forEach(stat => {
    statsObserver.observe(stat);
});

// Parallax Effect for Hero Image
window.addEventListener('scroll', () => {
    const scrolled = window.pageYOffset;
    const heroImage = document.querySelector('.phone-mockup');
    if (heroImage) {
        heroImage.style.transform = `translateY(${scrolled * 0.3}px)`;
    }
});

// Copy to Clipboard for Email (if needed)
document.querySelectorAll('a[href^="mailto:"]').forEach(link => {
    link.addEventListener('click', (e) => {
        const email = link.textContent;
        if (navigator.clipboard) {
            navigator.clipboard.writeText(email).then(() => {
                // Optional: Show toast notification
                console.log('Email copied to clipboard');
            });
        }
    });
});

// Service Card Interaction
document.querySelectorAll('.service-card').forEach(card => {
    card.addEventListener('click', () => {
        const serviceName = card.querySelector('h3').textContent;
        // Navigate to download section or show modal
        const downloadSection = document.querySelector('#download');
        if (downloadSection) {
            downloadSection.scrollIntoView({ behavior: 'smooth' });
        }
    });
});

// Form Validation (if you add a waitlist form)
const validateEmail = (email) => {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
};

// Track Download Button Clicks (for analytics)
document.querySelectorAll('.download-btn:not(.disabled)').forEach(btn => {
    btn.addEventListener('click', (e) => {
        // Add analytics tracking here
        console.log('Download button clicked:', btn.href);
        
        // Example: Google Analytics
        if (typeof gtag !== 'undefined') {
            gtag('event', 'download_click', {
                'event_category': 'engagement',
                'event_label': 'app_download'
            });
        }
    });
});

// Detect if user is on mobile
const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);

if (isMobile) {
    // Add mobile-specific behaviors
    document.body.classList.add('mobile');
    
    // Show app download CTA more prominently on mobile
    const downloadSection = document.querySelector('.section-download');
    if (downloadSection) {
        downloadSection.style.position = 'sticky';
        downloadSection.style.bottom = '0';
    }
}

// Lazy Loading Images
if ('loading' in HTMLImageElement.prototype) {
    const images = document.querySelectorAll('img[loading="lazy"]');
    images.forEach(img => {
        img.src = img.dataset.src;
    });
} else {
    // Fallback for browsers that don't support lazy loading
    const script = document.createElement('script');
    script.src = 'https://cdnjs.cloudflare.com/ajax/libs/lazysizes/5.3.2/lazysizes.min.js';
    document.body.appendChild(script);
}

// Performance: Preload critical resources
const preloadLink = document.createElement('link');
preloadLink.rel = 'preload';
preloadLink.as = 'image';
preloadLink.href = 'assets/app-screenshot.png';
document.head.appendChild(preloadLink);

// Easter egg: Konami code
let konamiCode = [];
const konamiPattern = ['ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'ArrowLeft', 'ArrowRight', 'b', 'a'];

document.addEventListener('keydown', (e) => {
    konamiCode.push(e.key);
    if (konamiCode.length > konamiPattern.length) {
        konamiCode.shift();
    }
    if (JSON.stringify(konamiCode) === JSON.stringify(konamiPattern)) {
        document.body.style.animation = 'rainbow 2s infinite';
        setTimeout(() => {
            document.body.style.animation = '';
        }, 5000);
    }
});

// Add rainbow animation
const style = document.createElement('style');
style.textContent = `
    @keyframes rainbow {
        0% { filter: hue-rotate(0deg); }
        100% { filter: hue-rotate(360deg); }
    }
`;
document.head.appendChild(style);

console.log('%c🤝 HireMeBuddy', 'font-size: 24px; font-weight: bold; color: #6366f1;');
console.log('%cMade with ❤️ in Namibia', 'font-size: 14px; color: #64748b;');
console.log('%cInterested in joining our team? Email hello@hiremebuddy.app', 'font-size: 12px; color: #10b981;');

