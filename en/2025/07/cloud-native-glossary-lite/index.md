# Cloud Native Glossary Lite


Reference: https://glossary.cncf.io/

<!--more-->

---

## 🧱 Architecture & Applications

- **Monolithic Apps**: A monolithic application contains all functionality in a single deployable program  
    > Devolving an application into microservices increases its operational overhead — there are more things to test, deploy, and keep running  
    > Early in a product's lifecycle, it may be advantageous to defer this complexity and build a monolithic application until the product is determined successful  
    > A well-designed monolith can uphold lean principles by being the simplest way to get an application up and running  
    > When the business value of the monolithic application proves successful, it can be decomposed into microservices  
    > Crafting a microservices-based app before it has proven valuable may be premature spending of engineering effort  
    > If the application yields no value, that effort becomes wasted  

- **Microservices**: Separating functionality into different microservices, making them easier to deploy, update, and scale independently
- **Distributed Apps**: Functionality broken down into multiple smaller independent parts that can run simultaneously in multiple locations, tolerate more failures, and have scaling capabilities that individual application instances don't possess
- **Distributed Systems**: A collection of autonomous computing elements connected by a network, appearing as a single coherent system to users
- **Client Server Architecture**: Application logic implemented in remote servers, allowing application updates without modifying client logic
- **Loosely Coupled Architecture**: Application components built independently, each designed to perform specific functions for use by any number of other services
- **Tightly Coupled Architecture**: Many application components depend on each other, where changes to one component may affect others, potentially speeding up initial development cycles
- **Event Driven Architecture**: Events are any changes to application state, defining event producers (sources) and consumers (receivers), with central event hubs (like Kafka) ensuring event flow
- **Stateless Apps**: State refers to any data an application needs to store to run as designed; these apps don't save any client session state data, with each session executing as if it's the first time, responses not depending on previous session data (like search engines)
- **Stateful Apps**: Client session state temporarily stored in memory or persistently in local disk or database systems
- **Vertical Scaling**: Technique to increase system capacity by adding CPU and memory to a single node when workload increases
- **Horizontal Scaling**: Technique to increase system capacity by adding more nodes rather than adding more computing resources to a single node

## 🚢 Containers & Orchestration

- **Container**: Provides an isolated runtime environment, allowing different applications to run in independent environments with separate file systems, networks, and process spaces
- **Container Image**: Immutable static files containing applications with their runtime dependencies
- **Containerization**: Process of bundling applications with their runtime dependencies into container images
- **Container Orchestration**: Container orchestration tools act like conductors directing numerous containers (musicians), ensuring each container performs its role
- **Kubernetes**: Often abbreviated as K8S, a popular open-source container orchestration tool
- **Pod**: The most basic deployable unit in Kubernetes environment, can contain one or more containers
- **Cluster**: A group of computers or applications connected by a network working together for a common goal, eliminating single points of failure
- **Nodes**: A computer that can work with other computers (or nodes) to accomplish a common task

## 🧩 Service Governance

- **API Application Programming Interface**: A clear, understandable way for computer programs to interact and share information
- **API Gateway**: Tools that aggregate APIs from multiple applications for one-stop management
- **Load Balancer**: Acts as a traffic proxy, distributing network traffic across multiple servers, improving application reliability during traffic peaks
- **Service**: Specific definitions vary by context; in microservices architecture, typically refers to independently deployable functional modules
- **Service Proxy**: Acts as a "middleman" intercepting and forwarding service traffic, collecting traffic information and applying rules for traffic management and security control
- **Service Discovery**: Continuously tracks applications in the network, providing a common place to find and identify different services so applications can find each other
- **Service Mesh**: Unified management of inter-service communication, adding reliability, observability, and security features without code changes

## ☁️ Service Models

- **Cloud Computing**: On-demand provision of computing resources (like CPU, network, and disk capabilities) via the internet, divided into private and public clouds depending on whether cloud infrastructure is dedicated to an organization or shared as a public service
- **IaaS Infrastructure-as-a-Service**: Cloud providers offer physical or virtual computing, storage, and network resources with on-demand, pay-as-you-go billing
- **PaaS Platform-as-a-Service**: Provides general infrastructure to application developers in a fully automated manner, allowing developers to focus more time and effort on writing application code
- **CaaS Container-as-a-Service**: No need to manage underlying infrastructure for container operation, automating container deployment and management
- **DBaaS Database-as-a-Service**: Cloud providers manage database configuration, backup, patching, upgrades, monitoring, etc., while developers only use the database
- **SaaS Software-as-a-Service**: Software installed, maintained, upgraded, and secured by vendors, handling scaling, availability, and capacity issues; users access software via the internet with pay-as-you-go models
- **Serverless**: Cloud-native development model where developers build and run applications without managing servers, with cloud providers handling configuration, maintenance, and scaling of server infrastructure
- **Managed Services**: Software services operated and managed by third parties, allowing users to focus on core business and reduce operational burden

## 🛠 DevOps

- **DevOps**: Integration of development and operations, emphasizing collaboration, automation, and continuous delivery/deployment, giving teams ownership of the entire application lifecycle, minimizing handoffs, improving code quality, and reducing deployment risks
- **CI Continuous Integration**: Regular integration of code changes with automated testing, improving collaboration efficiency and code quality
- **CD Continuous Delivery**: Automatic deployment of code changes to acceptance environments, ensuring software is fully tested before production deployment
- **CD Continuous Deployment**: Automatic deployment of tested environment code changes to production, going one step further than continuous delivery
- **Canary Deployment**: Gradually shifting traffic from old to new versions, testing on a small scale first, allowing quick rollback if issues arise, reducing deployment risks; named after miners using canaries' sensitivity to harmful gases for safety warnings
- **Blue-Green Deployment**: Maintaining two environments simultaneously, "blue" as current production and "green" as new production, achieving zero-downtime deployment through rapid traffic switching, suitable for scenarios requiring complete synchronous changes due to lack of backward compatibility
- **Auto Scaling**: System automatically increases or decreases resources based on demand, improving elasticity and efficiency
- **Self Healing**: Recovery from failures without any human intervention

## 🔐 Reliability & Security

- **SRE Site Reliability Engineering**: Discipline combining operations and software engineering; DevOps focuses on getting code into production, SRE ensures code runs properly in production
- **CE Chaos Engineering**: Actively injecting failures in production to validate system resilience and self-healing capabilities, building confidence in system ability to withstand turbulence and unexpected conditions
- **Security Chaos Engineering**: Executing proactive security experiments on distributed systems, building confidence in system ability to resist turbulence and malicious conditions
- **Cloud Native Security**: Integrating security throughout the cloud-native application lifecycle, adapting to cloud-native environment characteristics of rapid code changes and highly ephemeral infrastructure
- **Zero Trust Architecture**: Never trust, always verify; a method of IT system design and implementation that completely eliminates trust
- **Firewall**: Systems that filter network traffic based on specific rules; firewalls can be hardware, software, or a combination
- **TLS Transport Layer Security**: Protocol designed to provide higher security for network communications, preventing data eavesdropping and tampering
- **mTLS mutual Transport Layer Security**: Ensures bidirectional traffic between clients and servers is secure and trusted, with no unauthorized parties eavesdropping or impersonating legitimate requests

## 🔄 Infrastructure

- **IaC Infrastructure-as-Code**: Defining and managing infrastructure with code, achieving automation, reproducibility, and version control, reducing human configuration errors
- **PaC Policy-as-Code**: Defining and automatically executing policies with machine-readable files, improving compliance and automation, reducing human errors
- **Immutable Infrastructure**: Computer infrastructure (like VMs, containers, network devices) that cannot be changed once deployed, making it easier to identify and mitigate security risks
- **Bare Metal Machine**: Physical servers running operating systems and applications directly, without virtualization layer, with exclusive resources and optimal performance
- **Data Center**: Buildings or facilities designed specifically to house servers, ensuring secure, stable, and efficient operation of computing resources
- **Edge Computing**: Moving computing and storage resources from the center to near data sources, improving real-time performance and efficiency, reducing latency

## 🧠 System Characteristics

- **Scalability**: System can easily expand capacity by adding nodes or resources to meet growing business demands
- **Portability**: Software can run across different operating systems or cloud environments, reducing dependency on specific platforms, facilitating migration and reuse
- **Observability**: Gaining insights into system state and taking corrective measures through collection and analysis of system information
- **Reliability**: System's ability to respond to failures, continuing to operate when components fail
- **Idempotence**: Producing the same result regardless of how many times executed; if parameters are the same, an idempotent operation won't affect the application it calls

## 📁 Development & Collaboration

- **Version Control**: System that continuously records changes to individual files or groups of files, helping developers act quickly and maintain efficiency while storing change records and providing conflict resolution tools
- **Agile Software Development**: Emphasizing iterative development and team self-organization, continuously delivering value, responding quickly to changes, adapting to complex requirements
- **Debugging**: Faults are defects or problems causing incorrect or unexpected results; software development is complex, and writing code without introducing faults is nearly impossible; debugging is the process of finding and resolving faults to achieve expected results
- **Shift Left**: Implementing testing, security, or other development practices in early stages of the software development lifecycle (viewing the lifecycle as a left-to-right execution timeline), discovering and solving problems early, reducing later repair costs

## 🧬 Cloud Native Philosophy

- **Cloud Native Apps**: Applications specifically designed to leverage cloud computing innovations, easily integrating with cloud architecture and fully utilizing cloud resources and scalability features
- **Cloud Native Tech**: Also called cloud-native technology stack, enabling organizations to build and run scalable applications in modern dynamic environments like public, private, and hybrid clouds, fully leveraging cloud computing advantages
- **Multitenancy**: Sharing the same software while providing each tenant with an isolated environment (work data, settings, credential lists, etc.), serving multiple tenants simultaneously

